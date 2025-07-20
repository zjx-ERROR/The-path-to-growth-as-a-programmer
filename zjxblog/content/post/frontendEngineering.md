---
title: "FrontendEngineering"
date: 2025-07-17T23:54:39+08:00
categories: [前端工程]
draft: true
---


# 基本功

## JavaScript

### 类型

基本类型：undefined、null、boolean、number、string、object、symbol

引用类型：Boolean、Number、String、Symbol、Object、Array、Map、Set

### String

```js
String("a") === "a";
new String("a") === new String("a");
// 这两段的结果是不一样的
// String("a")是对内置函数String的普通函数调用，在ECMAScript规范中，这会触发ToString操作，返回一个primitive string类型，既是"a"
// 而new String("a")实际调用了String构造器，并创建了一个String对象（包装类型）：new String("a") -> Object，每次new都会分配新的对象（不同的堆内存地址）。
```

### Number

![number](/images/js_number.png)

```js
Math.pow(2, 53) === Math.pow(2, 53) + 1
// 这两个值相等是因为尾数位能够精确表示的整数范围是
-(2^53 - 1) 到 2^53 - 1
超过这个范围的整数，JavaScript就无法保证“加 1”这样的最小增量能被精确表示。
在2^52到2^53之间，相邻浮点数的间距是2^(52-52) = 1
到2^53到2^54这个区间，相邻浮点数的间距变成了2^(53-52) = 2
即：
2^53 = 9007199254740992
2^53 + 1 = ——（无法表示，四舍五入回 2^53）
2^53 + 2 = 9007199254740994
2^53 + 4 = 9007199254740996
```

### Symbol

在ES6+里，Symbol是一种新的原始类型，用来生成唯一且不可变的值，典型用途是在对象上定义不会冲突的属性键。

```js
// 创建一个Symbol
const symA = Symbol("des");
// 在全局注册表中注册或获取同名Symbol
const symB = Symbol.for("config");
```

### Prototype

在JavaScript中，一切对象都是通过原型链相互关联，实现属性和方法的继承。

- 原型对象

每个对象（除了Object.prototype）内部都有一个指向另一个对象的链接，称为[[Prototype]]

- 原型链

属性查找时，如果对象本身没有对应属性，就会沿着[[Prototype]]向上查找，直到遇到null为止。

- 构造函数与.prototype

每个函数对象（Function）都有一个可写属性.prototype，默认是一个空对象，专门用来存放该构造函数所有实例共享的属性或方法。

```js
function Person(name){
    this.name = name;
}
Person.prototype.greet = function(){
    console.log('Hello');
}
```

- __proto__

几乎所有通过对象字面量、构造函数new、Object.create()等方式创建的对象，都有一个内部属性[[Prototype]]，大多数浏览器里它映射为.__proto__，指向它”继承“的属性和方法所在的对象。

在ES标准中常用Object.getPrototypeOf、Object.setPrototypeOf，而不是.__proto__

ES6的class和extends只是语法糖，本质仍是基于原型链的继承。

## BOM

### location

代表当前窗口的URL信息，可读写

- hash

设置或返回从#开始的URL

- host

设置或返回主机名和当前URL的端口号

- hostname

设置或返回当前URL主机名

- href

设置或返回完整的URL

- pathname

设置或返回当前URL的路径部分

- port

设置或返回当前URL的端口号

- search

设置或返回从?开始的URL

- reload

重载页面

- assign

跳转

### navigation

提供浏览器和操作系统的信息

- userAgent

浏览器和操作系统的信息

- clipboard

剪贴板

- keyboard

精确地管理物理键盘的布局映射和按键捕获行为

- geolocation

用于获取用户设备的地理位置信息

- mediaDevices

用于访问多媒体输入设备（摄像头、麦克风、屏幕共享等）的接口

- serviceWorker

是运行在浏览器后台、独立于网页线程的脚本，能够拦截网络请求、管理缓存，并在离线或网络不佳时为页面提供资源及消息推送等能力

### history

用于管理浏览器的历史记录栈。通过它，开发者可以控制用户浏览历史，比如前进、后退、跳转等行为，并配合单页应用实现路由切换

- back

回退到上一个历史记录

- forward

前进到下一个历史记录

- go

跳转到第n条历史记录

- pushState/replaceState

用于单页应用中实现地址栏变化但页面不刷新的路由效果

### performance

用于获取页面加载性能、资源加载时间等高精度的时间数据

### window

window对象是所有BOM接口的全局入口，也是JavaScript运行时的全局对象。

### proxy

在ES6里，Proxy是一个用于拦截并自定义堆目标对象基本操作行为的内建构造函数。它可以让你在对象被访问、设置、枚举、函数调用等一系列操作时，插入自定义逻辑。

```js
// target：被包装的原始对象，可以时普通对象、数组、函数、另一个Proxy
// handler：定义陷阱（traps）的对象，每个trap对应一种被拦截的操作。
const proxy = new Proxy(target, handler);
```

常用trap

|trap名称|拦截操作|方法签名示例
|---|---|--|
|get|读取属性|get(target, prop, receiver)|
|set|写入属性|set(target, prop, value, receiver)|
|has|in 操作符|has(target, prop)|
|deleteProperty|delete obj[prop]|deleteProperty(target, prop)|
|ownKeys|Object.keys\Reflect.ownKeys等|ownKeys(target)|
|apply|以函数方式调用proxy（当target是函数）|apply(target, thisArg, argsList)|
|construct|用 new proxy(...) 构造实例|construct(target, argsList, newTarget)
|


```js
// 示例
const obj = { a: 1, b: 2 };
const logged = new Proxy(obj, {
  get(target, prop, receiver) {
    console.log(`读取属性 ${String(prop)}`);
    return Reflect.get(target, prop, receiver);
  },
  set(target, prop, value, receiver) {
    console.log(`设置属性 ${String(prop)} = ${value}`);
    return Reflect.set(target, prop, value, receiver);
  }
});
```

### reflect

ES6引入的一个内建全局对象，它提供了一系列与语言底层操作一一对应的方法，将原本散落在运算符和对象方法里的底层行为集中到了一个统一的API下。常见用途时在Proxy的handler中，将拦截到的操作委托回默认行为，避免直接使用原默认操作时触发自身的Proxy导致无限递归。


### indexedDB

是一种面向对象的本地数据库API，专为存储大量结构化数据而设计

## DOM

DOM时浏览器将HTML或XML文档解析后，构建出来的一棵以对象方式组织的树状结构，它让我们可以使用JavaScript动态地访问和操作网页内容

在DOM中DocumentFragment时一个轻量级的、最小的文档对象容器，它可以包含一部分DOM结构，但本身不属于主文档树。它主要作用时作为一个临时容器，用于批量构建和操作DOM元素，然后一次性插入页面，提升性能。

```js
const ul = document.getElementById("list");
const fragment = document.createDocumentFragment();

for (let i = 0; i < 1000; i++) {
  const li = document.createElement("li");
  li.textContent = `项目 ${i}`;
  fragment.appendChild(li); // 操作内存中的 DOM 片段
}

ul.appendChild(fragment); // 一次性插入页面
```


## CSS

### Flex

FlexBox是一种CSS3引入的布局模式，用于在容器中分配控件并对齐内容，特别适用于一维布局。

- 父容器常用属性（控制主轴、换行、对齐）

|属性|	含义|
|---|---|
|display: flex|	启用 Flex 布局|
|flex-direction|	主轴方向（row, row-reverse, column, column-reverse）|
|flex-wrap|	是否换行（nowrap, wrap, wrap-reverse）|
|justify-content|	主轴对齐方式（如居中、间隔）|
|align-items|	交叉轴对齐方式（垂直方向）|
|align-content|	多行时的交叉轴对齐方式|

- 子元素常用属性（单个项目控制）

|属性|	含义|
|---|---|
|flex	|简写形式，包含 grow、shrink、basis|
|flex-grow	|项目放大比例|
|flex-shrink	|项目缩小比例|
|flex-basis	|初始大小|
|align-self	|允许单个项目独立设置交叉轴对齐方式|
|order	|控制项目排列顺序（数字越小越靠前）|


### Grid

Grid是CSS3提供的一种强大的二维布局系统，允许开发者在网页中按照行与列的形式精确地组织内容。与FlexBox的一维布局不同，Grid支持对横向和纵向同时控制，非常适合实现复杂的页面结构。

- 关键概念

|概念	|说明|
|---|---|
|容器（Grid Container）	|设置 display: grid 的元素|
|单元格（Grid Cell）	|网格中的最小空间单元|
|行/列（Row/Column）	|网格的水平和垂直划分|
|区域（Grid Area）|	多个单元格组成的区域|

### 预处理器

- 主流预处理器

|工具	|语言特性	|生态\兼容|
|---|---|---|
|Sass/SCSS	|最成熟，语法两种：.sass（缩进）/.scss（类似 CSS）	|Node、Ruby、Dart 实现；与大多数构建工具集成|
|Less	|语法更贴近 CSS，运行时可在浏览器编译	|与 Ant Design、Bootstrap 等集成度高|
|Stylus	|语法极简，可自由省略括号、分号	|深受 Vue 社区青睐|


## 底层技术

### 浏览器缓存

1. Service Worker 缓存

- 概念

Service Worker通过标准的Cache API管理的缓存，与HTTP缓存无关，由开发者在脚本里完全控制。常见于PWA离线支持。

- 特点
  - 可编程：在install、fetch等事件里，自定义哪些请求要缓存、何时更新、何时回退缓存
  - 持久：缓存数据存储在浏览器的IndexedDB里，除非调用cache.delete()或清除站点数据，否则一直保留
  - 离线可用：即使网络断开，也能返回缓存响应，实现离线体验
- 示例

```js
self.addEventListener('install', e => {
  e.waitUntil(
    caches.open('v1').then(cache =>
      cache.addAll(['/index.html', '/styles.css', '/app.js'])
    )
  );
});

self.addEventListener('fetch', e => {
  e.respondWith(
    caches.match(e.request).then(resp => resp || fetch(e.request))
  );
});
```

2. 内存缓存（Memory Cache）

- 概念

浏览器在内存中为页面最近请求的资源保留的一份拷贝、访问速度最快。

- 特点
  - 生命周期短：页面关闭或内存紧张时就会被回收
  - 高优先级：比磁盘缓存更新快、省时；如果资源在内存缓存中命中，浏览器就不会取磁盘或发起网络请求。
  - 大小有限：一般浏览器会根据内存使用情况动态调整。

3. 磁盘缓存（Disk Cache）
- 概念

浏览器将静态资源和HTTP响应数据存储在本地磁盘上，供后续重用。

- 特点
  - 持久性：关机后仍保留，直到缓存过期或用户清理。
  - 按HTTP头控制：遵循服务器返回的Cache-Control、Expires、ETag、Last-Modified等字段，自动管理缓存有效期与校验。
  - 空间受限：浏览器会根据磁盘配额和策略回收旧资源。
- 命中逻辑
  - 强制缓存：如果在有效期内，直接返回缓存，无需请求。
  - 协商缓存：过期后发条件请求（带If-None-Match/If-Modified-Since），服务器返回304 Not Modidied则继续用缓存。

4. 推送缓存（Push Cache）

- 概念

HTTP/2中的Server Push允许服务器在客户端尚未请求某资源时，主动推送到客户端，并保存在浏览器的推送缓存中。

- 特点
  - 预加载：服务器在响应HTML时，可同时推送CSS、JS、字体等资源
  - 按同源和路径匹配：只有与当前页面同源，且URL匹配的请求才可命中这些预推送资源。
  - 一次性：推送缓存只在当前连接存活，断开连接就会失效。
  
5. 缓存优先级
   1. 内存缓存
   2. 磁盘缓存
   3. Service Worker缓存
   4. 推送缓存

### 浏览器渲染

1. 刘阿龙年起渲染流程概览
   1. HTML解析->构建DOM树

    浏览器接收HTML文本，解析成一颗节点树（DOM），每个标签对应一个DOM节点

   2. CSS解析->构建CSSOM树

    浏览器解析所有内联和外链的样式表，生成CSSOM（CSS Object Model）树，描述各节点的样式规则和层叠关系。

   3. DOM+CSSOM合并->构建Render Tree

    将两棵树结合，只保留可见节点，并附加计算后的样式，得到渲染树（Render Tree）。

   4. 布局（Layout/Reflow）

    根据渲染树计算每个节点的几何信息（位置和大小）。这一步叫回流（Reflow）或重布局。

   5. 绘制（Paint）

    将各个节点按层级依次绘制到栅格（layers）上，生成绘制列表（Paint List）。

   6. 合成（Composite）

    将各个绘制层合并（合成）到最终屏幕上，呈现给用户。

2. 回流（Reflow）

回流就是重新计算渲染树中节点的几何尺寸和位置。任何影响护具的改动都会触发回流，常见触发源包括：

   1. DOM结构变化：新增/删除节点等；
   2. 内容变化：膝盖文本内容等；
   3. CSS样式变化：改变会影响布局的属性，如display、position等
   4. 查询布局信息：读取会触发布局的属性/方法，如offsetWidth、scrollTop、getComputedStyle等；如果在同一脚本里写入然后立刻读取，就会导致强制同步回流（Layout Thrash）

3. 应对回流的措施
    1. 批量DOM操作
        - 使用DocumentFragment、隐藏容器（display:none）或一次性innerHTML拼接，完成后再插入文档
        - 减少反复的增删改查
    2. 避免强制同步回流
        - 将写操作（改变样式、属性）和读操作（获取尺寸、样式）分离到不同的脚本块
        - 或使用requestAnimationFrame把读写分帧执行
    3. 使用CSStransform & opacity
        - 这些属性只会触发合成（Composite），不会引起回流和重绘
        - 如做动画时，优先 transform: translate()、scale()、opacity
    4. 合并多次样式修改
        - 如果要改多个样式，最好用element.style.cssText = '...' 或者添加／切换class，而不是多次单独赋值
    5. 虚拟化长列表
        - 对于包含大量条目的列表，只渲染可视区域的DOM，滚动时动态增删，减少节点数量
    6. 慎用复杂布局
        - 避免过深的嵌套、过多的 CSS 计算
        - 在必要时，可考虑把部分固定内容渲染成图片或 Canvas
    7. 开启合成层
        - 对需要频繁动画的元素，如：will-change: transform 或 translateZ(0)，提示浏览器提前创建合成层，减少主线程开销
  
