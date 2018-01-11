Redmine::Plugin.register :redmine_wiki_to_issue do
  name 'Redmine Wiki To Issue plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
end



Redmine::WikiFormatting::Macros.register do
  desc <<'EOF'
  generate issue(s) from wiki(s). Examples:\n\n<pre>{{wiki_to_issue(wiki_page_name)}}\n   </pre>
        this will create a issue: subject=wiki_page_name.title, description=wiki_page_name.content, project=wiki_page_name.project, author=current_user.
      what's more, if wiki_page_name.content include <pre> child_issue:[[wiki_page_name2]] </pre>, another child issue will be created.
      this child process could be a recursion. but the recursion depth is limited to 10.

EOF

  macro :wiki_to_issue do |wiki_content_obj, args|
    # Parse the file argument. find wiki page

    page = Wiki.find_page(args.first.to_s, :project => @project)
    raise 'Page not found' if page.nil? || !User.current.allowed_to?(:view_wiki_pages, page.wiki.project)

    #http://192.168.1.173:3000/wikitoissuectl/wikitoissue/1/2

    sub1=' [['+args.first.to_s+']] '
    out1 = textilizable(sub1 )

    out2=link_to('create issue from wiki',
                 controller: 'wikitoissuectl', action: 'wikitoissue',
                 project_id: page.wiki.project.identifier.to_s, wiki_id: page.title.to_s)

    #out1= '<a href="/wikitoissuectl/wikitoissue/'+page.wiki.project.identifier.to_s+'/'+page.title.to_s+'"> ---create issue from wiki ---</a>'
    #out2= '<a href="/projects/'+page.wiki.project.identifier.to_s+'/wiki/'+page.title.to_s+'">'+ args.first.to_s + '</a>'
    out="<div style=' border: #759fcf solid 1px'> ".html_safe  + ( out1 + out2 ).html_safe + "</div>".html_safe

    return out

    page_cont=page.content.text
    page_cont=page_cont.to_s
    first_line_index=page_cont.index("\n")
    if first_line_index>2
      first_line_index=first_line_index-1
    end

    if page_cont.to_s.length>(first_line_index+5)
      sub1 = page_cont.to_s[first_line_index,page_cont.to_s.length]
    else
      sub1 = "EMPTY"
    end
    formatting = Setting.text_formatting
    text = Redmine::WikiFormatting.to_html(formatting, sub1, :object => page.content)
    out = text.html_safe
    out =
        link_to(page.title,
                controller: 'wiki', action: 'show',
                project_id: page.project, id: page.title) + "<br/> <div style=' border: #759fcf solid 1px'> ".html_safe + text.html_safe + "</div>".html_safe

    out
  end
end





