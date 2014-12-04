cache @posts do
  atom_feed :language => 'en-US' do |feed|
    feed.title Preference.html.title
    feed.updated @posts.first.updated_at

    @posts.each do |post|
      feed.entry(post) do |entry|
        entry.url post_url(post)
        entry.title post.title
        entry.content markdown(post.content), :type => 'html'
        entry.updated(post.updated_at.strftime("%Y-%m-%dT%H:%M:%SZ"))

        entry.author do |author|
          author.name post.user.name
          author.email post.user.email
          author.uri root_url
        end
      end
    end
  end
end
