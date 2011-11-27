---
title: Using Twitter's Bootstrap and Less
layout: post
category: Nerdery
date: 2011-11-26
disqus-id: 2011-11-26-using-twitters-bootstrap-and-less
excerpt:
  I have to admit this site has been in bad shape for quite some time now. I decided to spend some time between turkey sandwiches this Thanksgiving weekend to fix it up a little. I'm not much of a designer so the thoughts of fixing up all the CSS was not very appealing to me. I decided to give Twitter's Bootstrap a try and hope that would take care of the hard parts while giving me a chance to try out LESS at the same time.
---

I have to admit this site has been in bad shape for quite some time now. I decided to spend some time between turkey sandwiches this Thanksgiving weekend to fix it up a little. I'm not much of a designer so the thoughts of fixing up all the CSS was not very appealing to me. I decided to give [Twitter's Bootstrap][twitter-bootstrap] a try and hope that would take care of the hard parts while giving me a chance to try out [LESS][less-css] at the same time.

One of the good parts of Bootstrap is how easy it is to learn to use the [grid system][bootstrap-grid] for the main layout. With a combination of `row`, `span[N]`, and `offset[N]` CSS classes it is easy to place items anywhere on the page using the grid. The more challenging aspect of using Bootstrap was figuring out how to make Bootstrap aware of the color theming I am using.

Bootstrap comes with a `variables.less` file that allows you to set some variables for theming. Even with these variables Bootstrap seems to assume you want a white background with black and gray text. To get around this I had to make a few changes.

First I had to edit `scaffolding.less`:
{% highlight css linenos %}
body {
  background-color: @baseColor;
  margin: 0;
  #font > .sans-serif(normal,@basefont,@baseline);
  color: @white;
}
{% endhighlight %}

 I updated the `background-color` to use the `@baseColor` variable set in `variables.less`. I also had to change the `color` attribute to `@white` to reflect the fact I'm using a dark background.

The other notable change was to `variables.less`:
{% highlight css linenos %}
// Grays
@black:             #494949;
@grayDark:          lighten(@black, 90%);
@gray:              lighten(@black, 75%);
@grayLight:         lighten(@black, 50%);
@grayLighter:       lighten(@black, 25%);
@white:             #fff;
{% endhighlight %}

Basically I set `@black` to be my background color. The background color I use is already dark so anything darker will not show up well. Because Boostrap assumes a white background with black text, I then reversed the gradients of grays making `@grayDark` actually be the lightest gray and `@grayLighter` be the darkest gray. I'm a stickler for descriptively named variables in my code so this made me feel a bit dirty, but it got the job done. Bootstrap uses these grays for headings and other elements.

It took me just a few short hours to incorporate Bootstrap into this site and convert the layouts to use the grid system. The end result is that the layout feels much more manageable and less fragile with the grid layout system provided by Bootstrap and Bootstrap gives a great set of default typography styling. I've now converted all my CSS to LESS and will probably use it on every project going forward.


[twitter-bootstrap]: http://twitter.github.com/bootstrap/
[less-css]: http://lesscss.org
[bootstrap-grid]: http://twitter.github.com/bootstrap/#grid-system
