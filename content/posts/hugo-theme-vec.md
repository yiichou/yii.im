+++
comments = false
date = "2016-09-09T16:52:42+08:00"
title = "A minimal hugo theme -- Vec"
toc = false

+++

# Vec

Vec is a minimal, clean and beautiful theme for [Hugo](http://gohugo.io/).

[Demo](http://yii.im).

[Repo](https://github.com/IvanChou/hugo-theme-vec).

![Vec screenshot](https://stc.ichou.cn/assets/90d226103db0d33cfc9738f7e31a2bf0.png)

![Vec screenshot2](https://stc.ichou.cn/assets/2070fd4f8c95bbb187e08a9595d12089.png)

## Installation

```
mkdir themes
cd themes
git clone https://github.com/IvanChou/hugo-theme-vec vec
```

See the [official docs](http://gohugo.io/themes/installing) for more information.

## Configuration
You could add `params` into your site's `config.toml` file:

```
[params]
  Keywords = "key, 关键字, キーワード"
  Description = "There are some words to describe your site"
  
  Avater = "//chou.oss-cn-hangzhou.aliyuncs.com/yii.im/avatar.jpg"
  SelfIntro = "Just a worm, seek for true, live in shadow, no more..." 
  
  GithubID = "Your Github ID"
  TwitterID = "Your Twitter ID"
  FacebookID = "Your Facebook ID"
  LinkedInID = "Your LinkedIn ID"
  GoogleplusID = "Your Googleplus ID"
  AnalyticsID = "Your Google Analytics tracking code"
  DisqusID = "Your Disqus shortname"
```

If you use `config.yaml`, plz reformat them to yaml.

### Enable Disqus to your post

1. Add your Disqus Shortname to the site config file;
2. You can enable Disqus per-post, by adding `comments: true` (YAML) or `comments = true` (TOML) in the front matter of your post. To disable it, you can either change the value to `false` or just not include `comments` variable and its value at all. 

### Enable TOC to your post

If you need show table of contents per-post, adding `toc: true` (YAML) or `toc = true` (TOML) in the front matter of your post.

Please notice that TOC will be hidden when browser width is less than 920px.

## Build your site

Add `theme = "vec"` to your `config.toml`, then

```
# Build
hugo

# Run a server
hugo server
```
OR

```
hugo -t vec
hugo server -t vec
```


## License

Open sourced under [MIT license](https://github.com/IvanChou/hugo-theme-vec/blob/master/LICENSE.md).

