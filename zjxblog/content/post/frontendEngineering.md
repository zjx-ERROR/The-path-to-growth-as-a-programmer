---
title: "FrontendEngineering"
date: 2025-07-17T23:54:39+08:00
categories: [前端工程]
draft: true
---


# 基本功

## JavaScript

#### 类型

基本类型：undefined、null、boolean、number、string、object、symbol

引用类型：Boolean、Number、String、Symbol、Object、Array、Map、Set

#### String

```js
String("a") === "a";
new String("a") === new String("a");
// 这两段的结果是不一样的
// String("a")是对内置函数String的普通函数调用，在ECMAScript规范中，这会触发ToString操作，返回一个primitive string类型，既是"a"
// 而new String("a")实际调用了String构造器，并创建了一个String对象（包装类型）：new String("a") -> Object，每次new都会分配新的对象（不同的堆内存地址）。
```

#### Number

![number](/images/js_number.png)

