class WikitoissuectlController < ApplicationController
  unloadable


  def is_str_in_head(all_str, sub_str)
    len1=sub_str.length
    if all_str.length<len1
      return false,''
    end

    if all_str[0, len1]==sub_str
      return true, all_str[len1, all_str.length]
    end

    return false,''
  end


  def get_id_from_user_name(user_name)
    all_users=User.where([" login = :t1 ", {:t1=>user_name}]).all

    if all_users.count>0
      return all_users.first.id
    end
    return nil
  end

  def one_wiki_content_to_issue(subj, content_str, curr_proj_id, curr_proj)

    new_issue=Issue.new
    if subj.nil?
      new_issue.subject="empty"
    else
      new_issue.subject=subj
    end

    new_issue.project_id =curr_proj_id
    new_issue.status_id=1 # 新建
    new_issue.tracker_id=4 #调研
    new_issue.author_id=User.current.id
    new_issue.start_date =Time.now

    if  content_str.nil?
      content_str=""
    end
    lines=content_str.split("\n")

    curr_desc = nil
    child_issue_lines=[]
    lines.each do |one_line|

      is_macro=false

      is_macro, key_str=is_str_in_head(one_line,"{{wiki_to_issue(")
      if is_macro
        puts 'wiki_to_issue',key_str
        next
      end

      is_macro, key_str=is_str_in_head(one_line,":child_issue:")
      if is_macro
        child_issue_lines.push(key_str)
        puts 'child_issue',key_str
        next
      end

      #macros for machine:
      is_macro, key_str=is_str_in_head(one_line,":subject:")
      if is_macro
        new_issue.subject =key_str.strip
        puts 'subject',key_str
        next
      end
      is_macro, key_str=is_str_in_head(one_line,":assigned_to_id:")
      if is_macro
        new_issue.assigned_to_id =key_str.strip.to_i
        puts 'assigned_to_id',key_str
        next
      end

      is_macro, key_str=is_str_in_head(one_line,":project_id:")
      if is_macro
        new_issue.project_id =key_str.strip.to_i
        puts 'project_id',key_str
        next
      end

      is_macro, key_str=is_str_in_head(one_line,":priority_id:")
      if is_macro
        new_issue.priority_id =key_str.strip.to_i
        puts 'priority_id',key_str
        next
      end

      is_macro, key_str=is_str_in_head(one_line,":due_date:")
      if is_macro
        new_issue.due_date =Date.parse(key_str.strip.to_s)
        puts 'due_date',key_str
        next
      end

      #macros for human
      is_macro, key_str=is_str_in_head(one_line,":due_date+:")
      if is_macro
        new_issue.due_date =Time.now+ key_str.strip.to_i*24*60*60
        puts 'due_date+',key_str
        next
      end
      is_macro, key_str=is_str_in_head(one_line,":assigned_to:")
      if is_macro
        new_issue.assigned_to_id =get_id_from_user_name(key_str.strip.to_s)
        puts 'assigned_to',key_str
        next
      end
      #is_macro, key_str=is_str_in_head(one_line,":priority:")
      #if is_macro
      #  new_issue.priority_id =key_str.lstrip.to_i
      #  next
      #end

      # just content lines, add to desc string
      if curr_desc.nil?
        curr_desc=one_line
      else
        curr_desc=curr_desc+"\n"+one_line
      end

    end

    new_issue.description = curr_desc
    new_issue.save!
    #puts 'new issue saved',new_issue.id ,'saved ok???'

    child_issue_lines.each do|one_child_line|
      new_wiki_str = get_wiki_str_from_str(one_child_line)
      new_child_issue=nil
      if new_wiki_str.nil?
        #no wiki. just embedded lines?
        #{} for embedded lines
        one_child_line=one_child_line.strip
        if one_child_line[0]=="{" and  one_child_line[-1]=="}"
          one_child_line = one_child_line.gsub("\\n", "\n")
          puts one_child_line
          one_child_line=one_child_line[1, one_child_line.length-2]
          puts one_child_line
          new_child_issue = one_wiki_content_to_issue(nil,one_child_line,curr_proj_id, curr_proj)
        end
      else
        new_child_issue = one_wiki_to_issue(new_wiki_str, curr_proj)
      end

      if new_child_issue.nil?
        next
      end
      new_child_issue.parent_issue_id=new_issue.id
      new_child_issue.save!
    end
    #issue set child issue parent ==new_issue_id

    return new_issue
  end

  def one_wiki_to_issue(wiki_id, curr_proj)

    page=Wiki.find_page(wiki_id, {:project =>curr_proj})

    if page.nil?
      puts 'page is nil. just return', wiki_id, curr_proj
      return nil
    end

    if @issue_depth>10
      puts 'issue too deep?, just return:', wiki_id, curr_proj,@issue_depth
      return nil
    end

    @issue_depth=@issue_depth+1
    @issue_count=@issue_count+1

    new_issue = one_wiki_content_to_issue(page.title, page.content.text.to_s,page.wiki.project.id, page.wiki.project)

    #set new_issue_id  issue description ==curr_desc
    # save new_issue_id
    @issue_depth=@issue_depth-1
    return new_issue
  end

  def get_wiki_str_from_str(wiki_str_with_kk)
    #[[wiki_str]]
    index1=wiki_str_with_kk.index('[[')
    index2=wiki_str_with_kk.index(']]')

    if index1.nil? or index2.nil?
      return nil
    end

    return wiki_str_with_kk[index1+2..index2-1]
  end

  def wikitoissue
    #wiki_id could be wiki_title or project_identifier:wiki_title
    #config.logger = Logger.new(STDOUT)

    @project_id=params[:project_id]
    @wiki_id=params[:wiki_id]
    @issue_count=0
    @issue_depth=0

    created_issue = one_wiki_to_issue(@wiki_id, Project.find_by_identifier(@project_id))

    @created_issue_id=created_issue.id

    #puts created_issue
    # read wiki out
    # create one issue
    # find child_issue. delete this row.

  end
end
