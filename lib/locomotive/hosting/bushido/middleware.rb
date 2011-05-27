require 'rack/utils'

module Locomotive
  module Hosting
    module Bushido
      class Middleware

        BUSHIDO_JS_URL = 'http://localhost:4567/javascripts/bushido.js'

        include Rack::Utils

        def initialize(app, opts = {})
          @app = app
          @bushido_app_name = ENV['BUSHIDO_APP']
          @bushido_claimed = ENV['BUSHIDO_CLAIMED'] && ENV['BUSHIDO_CLAIMED'].to_s.downcase == 'true'
        end

        def call(env)
          status, headers, response = @app.call(env)

          if env["PATH_INFO"] =~ /^\/admin\//
            content = ""
            response.each { |part| content += part }

            # "claiming" bar + stats ?
            content.gsub!(/<\/body>/i, <<-STR
                <script type="text/javascript">
                  var _bushido_app = '#{@bushido_app_name}';
                  var _bushido_claimed = #{@bushido_claimed.to_s};
                  (function() {
                    var bushido = document.createElement('script'); bushido.type = 'text/javascript'; bushido.async = true;
                    bushido.src = '#{BUSHIDO_JS_URL}';
                    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(bushido, s);
                  })();
                </script>
              </body>
            STR
            )

            headers['content-length'] = bytesize(content).to_s

            [status, headers, [content]]
          else
            [status, headers, response]
          end
        end

      end
    end
  end
end