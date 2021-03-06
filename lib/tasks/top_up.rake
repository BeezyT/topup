namespace :top_up do
  desc "Release TopUp for external usage"
  task :release, :version do |task, args|
    if args[:version].blank?
      raise "usage: rake top_up:release[version]" 
    end
    
    require "action_controller"
    require "action_view"
    require "application"
    
    ActionController::Base.append_view_path File.join(RAILS_ROOT, "app", "views")
    
    timestamp = Time.now
    variables = [{:name => "css"   , :files => %w(style dashboard/style quicklook/style flatlook/style)},
                 {:name => "ie7fix", :files => %w(dashboard/ie7fix)},
                 {:name => "ie6fix", :files => %w(dashboard/ie6fix quicklook/ie6fix flatlook/ie6fix)},
                 {:name => "iefix" , :files => %w(iefix)}].collect{ |variable|
      
      value = variable[:files].collect{ |file|
        file = "public/stylesheets/top_up/#{file}.css"
        code = File.open(file).readlines.join(" ").gsub("/images/top_up/", "' + images_url + '")
      }.join(" ")
      {:name => variable[:name], :value => value}

    }
    variables << {:name => "html", :value => ActionView::Base.new(Rails::Configuration.new.view_path).render(:partial => "layouts/top_up")}
    variables.each{|variable| variable[:regexp] = Regexp.new("^\\s*var #{variable[:name]} = '.*'\;$")}
    
    # Define variables
    releases_dir    = "#{RAILS_ROOT}/assets/releases"
    release_dir     = "#{releases_dir}/#{args[:version]}"
    release_symlink = "#{releases_dir}/latest"
    
    # Create directories
    FileUtils.rm_r(release_dir) if File.exists?(release_dir)
    FileUtils.mkdir_p(release_dir)
    
    # Create files
    File.open("public/javascripts/top_up-pt.js"         , "w").puts(parse_library("top_up-pt", variables, args[:version], timestamp, true))
    File.open("public/javascripts/top_up.js"            , "w").puts(parse_library("top_up"   , variables, args[:version], timestamp))
    File.open("assets/examples/javascripts/top_up.js"   , "w").puts(parse_library("top_up"   , variables, args[:version], timestamp))
    File.open("assets/examples/javascripts/top_up-pt.js", "w").puts(parse_library("top_up-pt", variables, args[:version], timestamp, true))
    FileUtils.cp_r("assets/examples/.", release_dir)
    File.open("#{release_dir}/javascripts/top_up.js"    , "w").puts(parse_library("top_up"   , variables, args[:version], timestamp))
    File.open("#{release_dir}/javascripts/top_up-pt.js" , "w").puts(parse_library("top_up-pt", variables, args[:version], timestamp, true))

    # Create symbolic links
    File.delete(release_symlink) if File.exists?(release_symlink)
    File.symlink(args[:version], release_symlink)
    
    # Compress release using YUI compressor
    IO.popen "java -jar lib/yuicompressor-2.4.2.jar -v #{release_dir}/javascripts/top_up.js -o #{release_dir}/javascripts/top_up-min.js"
  end
  
  def parse_library(library, variables, version, timestamp, prototype = false)
    File.open("public/javascripts/development/#{library}.js").readlines.collect{ |line|
      index = nil
      variables.each_with_index{|variable, i| index = i if line.match variable[:regexp]}
      
      if index.nil?
        line.gsub(/\{(version|year|date)\}/) do |matched|
          case matched
          when "{version}"
            version
          when "{year}"
            timestamp.year.to_s
          when "{date}"
            timestamp.strftime("%Y-%m-%d %H:%M:%S +0100 (%a, %d %B %Y)")
          end
        end
      else
        variable   = variables[index]
        wrap_style = variable[:name] != "html" && !prototype
        value      = [("<style type=\"text/css\" media=\"screen\">" if wrap_style), 
                      variable[:value].gsub(/\s+/, " ").gsub("> <", "><").strip,
                      ("</style>" if wrap_style)].join
        
        "		var #{variable[:name]} = '#{value}';"
      end
    }
  end
  
  desc "Pack specified TopUp release"
  task :pack, :version do |task, args|
    if args[:version].blank?
      raise "usage: rake top_up:pack[version]" 
    end
    
    # Define variable
    releases_dir    = "#{RAILS_ROOT}/assets/releases"
    packed_dir      = "#{releases_dir}/packed"
    packed_symlink  = "#{packed_dir}/latest.zip"
    temp_dir        = "#{RAILS_ROOT}/tmp/release"
    
    # Create directories
    FileUtils.mkdir_p(packed_dir)
    FileUtils.rm_r(temp_dir) if File.exists?(temp_dir)
    FileUtils.mkdir_p(temp_dir)
    
    # Create symbolic links
    File.delete(packed_symlink)
    File.symlink("#{args[:version]}.zip", packed_symlink)
    
    # Delete .DS_Store files
    Dir.glob("#{releases_dir}/#{args[:version]}/**/.DS_Store") do |file|
      File.delete(file)
    end
    
    # Copy the release to the temp directory
    FileUtils.cp_r "#{releases_dir}/#{args[:version]}", temp_dir
    %w(jquery top_up-min.js top_up.js top_up-pt.js).each do |path|
      File.delete "#{temp_dir}/#{args[:version]}/#{path}"
    end
    
    # Pack release using tar
    system "cd #{temp_dir} && zip -r #{packed_dir}/#{args[:version]}.zip #{args[:version]}"
  end
end
