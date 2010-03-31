# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

require File.expand_path(File.join(File.dirname(__FILE__), 'html'))

module SC

  # Builds an HTML files.  This will setup an HtmlContext and then invokes
  # the render engines for each source before finally rendering the layout.
  class Builder::Test < Builder::Html
    
    def initialize(entry)
      super(entry)
      @layout = @target.config.test_layout || 'lib/test.rhtml'
    end
    
    protected 
    
    def render_entry(entry)
      entry.stage!

      case entry.ext
      when 'js'
        render_jstest(entry)
      when 'rhtml'
        entry.target.buildfile.invoke 'render:erubis',
          :entry    => entry, 
          :src_path => entry.staging_path,
          :context  => self
      end
    end
    
    def builder_mode
      :test
    end
    
    def default_content_for_key; :body; end
    
    # Renders an individual test into a script tag.  Also places the test 
    # into its own closure so that globals defined by one test will not 
    # conflict with any others.
    def render_jstest(entry)
      lines = readlines(entry.staging_path)
      pathname = entry.staging_path.gsub(/^.+\/staging\//,'').gsub(/"/, '\"')
      
      # wrap in a loader function if needed
      if entry.use_modules
        loader_name = entry.target.config.module_loader
        package_name = entry.manifest.package_name 
        lines.push %[#{loader_name}.require.ensure('#{package_name}', function() {\n  #{loader_name}.require('#{package_name}:#{entry.module_name}'); \n});]
        
      else
        lines.unshift %[if (typeof SC !== "undefined") {\n  SC.mode = "TEST_MODE";\n  SC.filename = "#{pathname}"; \n}\n(function() {\n]
        lines.push    %[\n})();]
      end
      
      # wrap in a script tag
      lines.unshift %[<script type="text/javascript">\n]
      lines.push %[\n</script>\n]
      
      @content_for_final = (@content_for_final || '') + lines.join("")
    end
    
  end
  
end
