class WikitoissuectlController < ApplicationController
  unloadable


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
    #new_issue=Issue.create({:subject=>page.title,:project_id=>page.wiki.project.id })
    new_issue=Issue.new
    new_issue.subject=page.title
    new_issue.project_id =page.wiki.project.id
    new_issue.status_id=1 # 新建
    new_issue.tracker_id=4 #调研
    new_issue.author_id=User.current.id

    lines=page.content.text.to_s.split("\n")
    curr_desc = nil
    #puts 'lines:', lines
    #puts 'lines end'
    child_issue_lines=[]
    lines.each do |one_line|
      if one_line.include?"child_issue:"
        child_issue_lines.push(one_line)
      else
        if curr_desc.nil?
          curr_desc=one_line
        else
          curr_desc=curr_desc+"\n"+one_line
        end
      end
    end

    #puts 'curr_desc',curr_desc
    #puts 'curr_desc end'
    new_issue.description = curr_desc
    #new_issue.title = page.title
    new_issue.save!
    #puts 'new issue saved',new_issue.id ,'saved ok???'

    curr_proj = page.wiki.project
    child_issue_lines.each do|one_child_line|
      new_wiki_str = get_wiki_str_from_str(one_child_line)
      new_child_issue = one_wiki_to_issue(new_wiki_str, curr_proj)
      if new_child_issue.nil?
        next
      end
      new_child_issue.parent_issue_id=new_issue.id
      new_child_issue.save!
    end
    #issue set child issue parent ==new_issue_id


    #set new_issue_id  issue description ==curr_desc
    # save new_issue_id
    @issue_depth=@issue_depth-1
    return new_issue
  end

  def get_wiki_str_from_str(wiki_str_with_kk)
    #[[wiki_str]]
    index1=wiki_str_with_kk.index('[[')
    index2=wiki_str_with_kk.index(']]')
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
