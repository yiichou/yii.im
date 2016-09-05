+++
date = "2015-10-13T23:49:09+08:00"
title = "Input[Date] 的 min 和 max 属性在 ios Safari 下不起作用"

+++

今天接到一个需求，要在商品下单页面加上一个日期选择控件让客户可以选择发货的时间，而且可选日期需要从下单日的两天后开始。

因为是 App 内嵌的 webview，而且之前前端大姐在写页面是并没有引用任何样式库，所以直接考虑用 Html5 原生的 Input[date] 控件来完成。

    // in angular
    $scope.minDate = new Date(Date.now() + 3600 * 48 * 1000); 

    // with angular
    <input type="date" ng-model="date" min="{{minDate | date:'yyyy-MM-dd'}}" />

    // A simple example
    <input type="date" min="2015-10-15" />

这段代码在 Android 上用起来十分酸爽，简单干净又达到了效果

然而，事情总不能是一帆风顺的， F’u’c’k The ios!

在 IOS 上，min 属性没有生效，可以选择任意的一个日期。网上查了下资料，偶有看到之前是支持的，而且有作者甚至专门在文章中强调这一点。

[http://tiffanybbrown.com/2013/10/24/date-input-in-html5-restricting-dates-and-thought-for-working-around-limitations/](http://tiffanybbrown.com/2013/10/24/date-input-in-html5-restricting-dates-and-thought-for-working-around-limitations/)

出于慎重，担心是由于项目中引用的各种 js 导致 min 失效，我又单独写了一个简单的、没有任何依赖的 html 页面来测试，最终还是证明

**IOS 的 Safari 并不支持对 input[date] 的范围限定！！**

遇到这样的情况，只能用 js 来做 hack，于是我做了这样的改进（涉及 angular，可略过）

    <input type="date" ng-model="message" min="{{minDate | date:'yyyy-MM-dd'}}" ng-change="checkDate()" />

    // Hack 4 IOS safari
    $scope.checkDate = function () {
        if (!$scope.date < minDate) { //意思一下，这么写其实不符合前面提到的需求
                !$scope.date = null;
            alert("仅支持预约两日以后的日期，请重新选择");
        }
    };

检测当 input 的值有变动时，触发 checkDate 操作，然后去做处理。但是结果是让人崩溃的，当选择的日期在小于 min 的值或空值间变动时，不会触发 checkDate

进一步 debug 后发现，选择的日期小于 min 的值或为空时，`$scope.date` 的值总是为 undefined，而 ng-change 实际上监听的是这个值的变化，所以并没有触发 checkDate。试着直接去 console input 本来的 value，发现是有值的，即当前显示的内容。所以 `$scope.date` 是被 angular 处理过的，并不是所见即所得，坑得我半天说不出话来，都怪自己不会 angular！

另一方面也发现，这里不应该监听 change，因为在选择时是拨转盘的方式，每经过一次值的变化就会触发一次，自然是不对的。正确的做法应该是监听 blur 事件。

继续改进：

    <input type="date" id="send-date" ng-model="message" min="{{minDate | date:'yyyy-MM-dd'}}" ng-blur="checkDate()" />

    // Hack 4 IOS safari
    $scope.checkDate = function () {
        if (!$scope.message && $("#send-date").val()) {
            setTimeout(function () {
                $("#send-date").val(null);
                alert("仅支持预约两日以后的日期，请重新选择");
            }, 1000) // 延时是为了等日期选择框消去，避免页面跳动
        }
    };

Hack 完成。

还想给 input[date] 加上 placeholder ？可以的，方法参考：

[http://stackoverflow.com/questions/20321202/not-showing-place-holder-for-input-type-date-field-ios-phonegap-app](http://stackoverflow.com/questions/20321202/not-showing-place-holder-for-input-type-date-field-ios-phonegap-app)

当然都不是完美的，onfocus 的方法第一次会呼出 Keyboard 而不是 Datepicker. 解决方案可以马上让他失去焦点再获得焦点，但是最后的效果，然并卵~

after + removeClass 的方法在 IOS 上几乎是完美的，但是在 Android 会有样式问题，可能是因为 Android 的 input[date] 即使值为空仍然会占行，导致 placeholder 的文本上面有一个空行。这个可以通过修改样式的方式来解决，但是 Android 何其多，越复杂越难维护，得不偿失~

于是最后我选择了在下面用一行 p 来显示提示，What a shit!

#### 总结

各浏览器对 Html5 的 input[date] 等新特性支持并没有想像的好！最乱大前端，果然名不虚传，我还是安心做 Ruby 好了~

