module HistoriesHelper
  def diff(h)
    l1 = "#{h.original['title'] || h.trackable.title} #{h.original['updated_at']}".shellescape
    l2 = "#{h.modified['title'] || h.trackable.title} #{h.modified['updated_at']}".shellescape
    o = h.original['content']
    m = h.modified['content']
    html = Diffy::Diff.new(o, m || " ", diff: ['-u', '-d', "-L#{l1}", "-L#{l2}"], include_diff_info: true, include_plus_and_minus_in_html: false, allow_empty_diff: true).to_s(:html)
    # html = html.scan(/(.*<\/ins><\/li>)\s*<li/m)[0][0] + "</ul></div>" unless m
    html.html_safe
  end
end
