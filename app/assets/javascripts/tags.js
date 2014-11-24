jQuery(function ($) { $(document).ready(function(){
  $('.tags-list > li > a').tooltip({
    placement: 'bottom',
    delay: { show: 100, hide: 800 },
    title: function () {
      return $(this).siblings('.tag-actions').html();
    },
  });
}); });
