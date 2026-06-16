# oui-icon-unix

一个针对 uni-app x 的字体图标库，基于 iconfont 字体文件，提供丰富、轻量、易集成的图标资源。

## 安装

```bash
# 通过 uni_modules 安装（推荐）
# 直接将 oui-icon-unix 文件夹放入 src/uni_modules/ 目录下即可
```

## 基础用法

### 字体图标

```vue
<template>
  <view>
    <!-- 基础用法 -->
    <oui-icon-unix name="home" />

    <!-- 自定义大小和颜色 -->
    <oui-icon-unix name="heart" size="24px" color="#ff4757" />
  </view>
</template>

<script lang="uts" setup></script>
```

## API

### Props

| 参数        | 类型      | 默认值  | 说明       |
| ----------- | --------- | ------- | ---------- | ---------------------------------- |
| name        | String    | -       | 图标名称   |
| size        | String \  | Number  | 16         | 图标大小，支持数字或带单位的字符串 |
| color       | String    | #000000 | 图标颜色   |
| customClass | String    | -       | 自定义类名 |
| customStyle | String    | -       | 自定义样式 |

### Events

| 事件名 | 说明           | 回调参数   |
| ------ | -------------- | ---------- |
| click  | 点击图标时触发 | event: any |

## 图标列表

### 常用图标

```vue
<!-- 基础图标 -->
<oui-icon-unix name="home" />
<!-- 首页 -->
<oui-icon-unix name="user" />
<!-- 用户 -->
<oui-icon-unix name="setting" />
<!-- 设置 -->
<oui-icon-unix name="search" />
<!-- 搜索 -->
<oui-icon-unix name="heart" />
<!-- 喜欢 -->
<oui-icon-unix name="star" />
<!-- 星标 -->
<oui-icon-unix name="location" />
<!-- 位置 -->
<oui-icon-unix name="phone" />
<!-- 电话 -->
<oui-icon-unix name="mail" />
<!-- 邮件 -->
<oui-icon-unix name="camera" />
<!-- 相机 -->

<!-- 方向图标 -->
<oui-icon-unix name="left" />
<!-- 左箭头 -->
<oui-icon-unix name="right" />
<!-- 右箭头 -->
<oui-icon-unix name="up" />
<!-- 上箭头 -->
<oui-icon-unix name="down" />
<!-- 下箭头 -->

<!-- 操作图标 -->
<oui-icon-unix name="plus" />
<!-- 加号 -->
<oui-icon-unix name="minus" />
<!-- 减号 -->
<oui-icon-unix name="close" />
<!-- 关闭 -->
<oui-icon-unix name="check" />
<!-- 勾选 -->
<oui-icon-unix name="edit" />
<!-- 编辑 -->
<oui-icon-unix name="delete" />
<!-- 删除 -->
```

### 社交图标

```vue
<oui-icon-unix name="wechat" />
<!-- 微信 -->
<oui-icon-unix name="qq" />
<!-- QQ -->
<oui-icon-unix name="weibo" />
<!-- 微博 -->
<oui-icon-unix name="alipay" />
<!-- 支付宝 -->
<oui-icon-unix name="facebook" />
<!-- Facebook -->
<oui-icon-unix name="twitter" />
<!-- Twitter -->
<oui-icon-unix name="linkedin" />
<!-- LinkedIn -->
<oui-icon-unix name="github" />
<!-- GitHub -->
```

### 文件图标

```vue
<oui-icon-unix name="file" />
<!-- 文件 -->
<oui-icon-unix name="folder" />
<!-- 文件夹 -->
<oui-icon-unix name="file-text" />
<!-- 文本文件 -->
<oui-icon-unix name="file-pdf" />
<!-- PDF文件 -->
<oui-icon-unix name="file-excel" />
<!-- Excel文件 -->
<oui-icon-unix name="file-word" />
<!-- Word文件 -->
<oui-icon-unix name="file-ppt" />
<!-- PPT文件 -->
<oui-icon-unix name="file-image" />
<!-- 图片文件 -->
```
