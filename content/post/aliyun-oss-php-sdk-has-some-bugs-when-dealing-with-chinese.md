+++
date = "2015-01-28T23:20:17+08:00"
title = "Aliyun OSS PHP SDK(ver.1.16) 对中文文件名的处理存在 BUG"

+++

**关键字: upload_file_by_file, utf-8, object_name**

我用这个 SDK 写了个 WordPress 的插件，由于自己用的 ACE，不需要这个 SDK，所以一直没发现这个问题

直到最近有两个人给我反馈无法上传中文名的文件，我想可能是编码问题，仔细的测试个自己的代码，没发现问题  
然后我跟踪一下 SDK 里的代码，瞬间凌乱了。。。。。

见 sdk.class.php line 1290

    /**
     * 上传文件，适合比较大的文件
     */
    public function upload_file_by_file($bucket, $object, $file, $options = NULL){
        // ..... 省略 ......
        if($this->chk_chinese($file)){
            $file = iconv('utf-8','gbk',$file);
        }
        // ..... 省略 .....
    }

只要判断包含中文就转 GBK，并没有检测输入字串是不是 utf8。这个倒是可以理解，因为或许在某个地方已经判断过了（我没通看源码，所以自我安慰一下），不过为什么要转成 GBK 呢？

在另一个地方有如下代码 line 2575

    /**
     * 检验object名称是否合法
     * object命名规范:
     * 1\. 规则长度必须在1-1023字节之间
     * 2\. 使用UTF-8编码
     */
    private function validate_object($object){
        $pattern = '/^.{1,1023}$/';
        if (empty ( $object ) || ! preg_match ( $pattern, $object )) {
            return false;
        }
        return true;
    }

UTF-8, 指定声明是 UTF-8 啊，前面那里转成 GBK 到底作何解释，排查原因就是由这一句导致报错的。难道 SDK 的作者默认自己的这个 SDK 就一定是在 Windows 服务器上运行的？不至于吧，再看不起中国的草根站长也不能一棍子把所有的用户都敲死吧。

说到底，这个是不是 BUG 我也没有确认？反正如果文件名有中文 报错是妥妥的，注释掉这3行，不转 GBK 反倒是没什么问题了。

为了解决用户们的问题，我对 line 1290 做了简单的修改

    if($this->chk_chinese($file) && $this->is_gb2312($file)){
      $file = iconv('gbk','utf-8',$file);
    }

**注意啦！我是因为我自己和我的插件用户几乎都是 Linux 服务器才这么处理的，Windows 的不要照搬**

另外吐槽一下 SDK 中 check_char() 和 is_gb2312() 两个方法的代码是不是有点太神似了，除了格式根本就是一模一样，这样写官方 SDK 给这么多人用真的好吗~

由于没有找到这个 SDK 的代码托管，（估计这货只存在阿里内部吧，）所以只能通过邮件联系作者，作者回复很快（我半夜发的，1小时内就收到回信了），但是得到的回应却是他在休陪产假<sub>~</sub> 论坛上的小编倒是承认了这是个 BUG，不过得等到之后的版本里才会做修正。

洗洗睡啦~

