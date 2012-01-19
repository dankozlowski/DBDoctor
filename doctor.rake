# This rake file is for all those little (or you know, huge) tasks to repair all the shit we fuck up.

namespace :doctor do
  
  # -------------------------------------------------------------
  # ---------- USE OLD COURSE AND CONTENT TO FIND COURSE --------
  # -------------------------------------------------------------
  
  desc "Retrieve data from old environment."
  task :get_old_content => :environment do
    
    courses = Course.all
    File.open("#{Rails.root}/db/tmp/courses.txt", "w+") do |f|
      for course in courses
        f.puts course.to_yaml
      end
    end
    
    contents = []
    
    for upload in Upload.all
      contents << upload
    end
    
    for link in Link.all
      contents << link
    end
    
    for comment in Comment.all
      contents << comment
    end
    
    contents = contents.flatten
    File.open("#{Rails.root}/db/tmp/contents.txt", "w+") do |f|
      for content in contents
        f.puts content.to_yaml
      end
    end
  end
  
  # -------------------------------------------------------------
  # ---------- FIND OLD COURSES WITH CONTENT --------------------
  # -------------------------------------------------------------
  desc "Tell me which objects have child objects."
  task :get_broken_courses => :environment do
    
    courses = Course.all
    courses_with_content = []
    all_courses = []
    
    for course in courses
      all_courses << course
      
      # Set a general flag for if a course has content
      fix_course = false
      content_count = 0
    
      if course.comments.count > 0
        fix_course = true
        for comment in course.comments
          content_count += 1
        end
      end
      
      if course.links.count > 0
        fix_course = true
        for link in course.links
          content_count += 1
        end
      end
      
      if course.uploads.count > 0
        fix_course = true
        for upload in course.uploads
          content_count += 1
        end
      end
      
      # This isn't really neccessary; I just felt incomplete without it.
      if course.feed_items.count > 0
        # fix_course = true
        for feed_item in course.feed_items
          # Feed items aren't real people!
          content_count += 0
        end
      end
      
      # It had content?  Great.  Add it to the array.
      if fix_course == true && content_count > 0
        puts "ID:#{course.id} - TITLE:#{course.name} \n"
        puts "COUNT:#{content_count} \n"
        puts "SCHOOL:#{course.term.school.short_name}\n"
        puts "\n"
        courses_with_content << course
      end
    end
      
    # Slap that shit in to a YAML.
    File.open("#{Rails.root}/db/tmp/get_courses.txt", "w+") do |f|
      for course in courses_with_content
        f.puts course.to_yaml
      end
    end
    
    File.open("#{Rails.root}/db/tmp/all_courses.txt", "w+") do |f|
      for course in all_courses
        f.puts course.to_yaml
      end
    end
  end
  
  # -------------------------------------------------------------
  # ---------- CORRECT IDS FOR COURSES  -------------------------
  # -------------------------------------------------------------
  desc "Let's recover our old course IDs from the YAML file created."
  task :repair_course_ids => :environment do
    
    all_courses  = YAML::load_documents(File.open("#{Rails.root}/db/tmp/all_courses.txt"))
    all_courses = all_courses.sort_by &:name
    broken_courses  = YAML::load_documents(File.open("#{Rails.root}/db/tmp/get_courses.txt"))
    broken_courses = broken_courses.sort_by &:name
    
    puts "The following courses IDs do not match: \n"
    for old_course in all_courses
      new_course = Course.where(:name => old_course.name, :term_id => old_course.term_id).first
      if new_course
        unless old_course == new_course
          puts "#{old_course.term.school.short_name} #{old_course.name}: ID #{old_course.id} => #{new_course.id}"
          for comment in old_course.comments
            comment.commentable_id = new_course.id
            comment.save
            puts comment
          end
          for link in old_course.links
            link.linkable_id = new_course.id
            link.save
            puts link
          end
          for upload in old_course.uploads
            upload.uploadable_id = new_course.id
            upload.save
            puts upload
          end
        end
      end
    end  
  end
  
  # -------------------------------------------------------------
  # ---------- FIND ALL OLD CONTENT FROM COURSES ----------------
  # -------------------------------------------------------------
  desc "Tell me which courses have associated objects."
  task :get_all_content => :environment do
    
    courses = Course.all
    
    comments    = []
    links       = []
    uploads     = []
    total_count = 0
    
    for course in courses
    
      if course.comments.count > 0
        for comment in course.comments
          puts comment
          comments << comment
          total_count += 1
        end
      end
      
      if course.links.count > 0
        for link in course.links
          puts link
          links << link
          total_count += 1
        end
      end
      
      if course.uploads.count > 0
        for upload in course.uploads
          puts upload
          uploads << upload
          total_count += 1
        end
      end
    end
      
    # Slap that shit in to a YAML.
    File.open("#{Rails.root}/db/tmp/comments.txt", "w+") do |f|
      for comment in comments
        f.puts comment.to_yaml
      end
    end
    File.open("#{Rails.root}/db/tmp/links.txt", "w+") do |f|
      for link in links
        f.puts link.to_yaml
      end
    end
    File.open("#{Rails.root}/db/tmp/uploads.txt", "w+") do |f|
      for upload in uploads
        f.puts upload.to_yaml
      end
    end
    
    puts "TOTAL: #{total_count}"
  end
  
  # -------------------------------------------------------------
  # ---------- COMPARE OLD CONTENT TO NEW -----------------------
  # -------------------------------------------------------------
  desc "Let's recover our old content IDs from the YAML files created."
  task :compare_content_ids => :environment do
    # Grab the old db data from the yaml files
    comments  = YAML::load_documents(File.open("#{Rails.root}/db/tmp/comments.txt"))
    links     = YAML::load_documents(File.open("#{Rails.root}/db/tmp/links.txt"))
    uploads   = YAML::load_documents(File.open("#{Rails.root}/db/tmp/uploads.txt"))
    
    # Find the new object and see if the IDs match
    puts "The following items have changed their ID:"
    for old_comment in comments
      new_comment = Comment.where(:content => old_comment.content, :student_id => old_comment.student_id).first
      if new_comment
        unless old_comment.id == new_comment.id
          puts "COMMENT #{old_comment.id} => #{new_comment.id}"
        end
      end
    end
    
    for old_link in links
      new_link = Link.where(:content => old_link.content, :student_id => old_link.student_id).first
      if new_link
        unless old_link.id == new_link.id
          puts "LINK #{old_link.id} => #{new_link.id}"
          
        end
      end
    end
    
    for old_upload in uploads
      new_upload = Upload.where(:title => old_upload.title, :student_id => old_upload.student_id).first
      if new_upload
        unless old_upload.id == new_upload.id
          puts "UPLOAD #{old_upload.id} => #{new_upload.id}"
        end
      end
    end
  end
  
end

