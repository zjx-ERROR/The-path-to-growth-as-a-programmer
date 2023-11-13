---
title: "Golang进阶技巧"
date: 2023-11-01T00:35:31+08:00
categories: [Golang]
draft: false
---


## 1. 值传递还是引用传递


***Go函数的参数始终按值传递。***

当结构体（或数组）类型的变量传递给函数时，整个结构都会被复制。

如果传递的是结构体指针，则复制的是指针，占8字节内存大小（64位系统），它指向的结构体不会被复制。

***这是否意味着传递结构体指针会更好吗？***

传递指针的结构体会被放置在堆内存中，而不是栈中。

如果动态分配的结构体占用多于直接传递，那么将它复制到栈中会更快：

```golang
package test

import (
    "os"
	"runtime/trace"
	"testing"
)

type S struct {
	a, b, c int64
	d, e, f string
	g, h, i float64
}

func byValue() S {
	return S{
		a: 1, b: 1, c: 1,
		d: "foo", e: "bar", f: "baz",
		g: 1.0, h: 1.0, i: 1.0,
	}
}

func byReference() *S {
	return &S{
		a: 1, b: 1, c: 1,
		d: "foo", e: "bar", f: "baz",
		g: 1.0, h: 1.0, i: 1.0,
	}
}

func BenchmarkByValue(b *testing.B) {
	var s S

	f, err := os.Create("stack.out")
	if err != nil {
		b.Fatal(err)
	}
	defer f.Close()
	err = trace.Start(f)
	if err != nil {
		b.Fatal(err)
	}
	for i := 0; i < b.N; i++ {
		s = byValue()
	}
	trace.Stop()
	b.StopTimer()
	_ = s
}

func BenchmarkByReference(b *testing.B) {
	var s *S
	f, err := os.Create("heap.out")
	if err != nil {
		b.Fatal(err)
	}
	defer f.Close()
	err = trace.Start(f)
	if err != nil {
		b.Fatal(err)
	}
	for i := 0; i < b.N; i++ {
		s = byReference()
	}
	trace.Stop()
	b.StopTimer()
	_ = s
}

```

让我们运行benchmarks：

> BenchmarkByValue-6       353830330	         3.368 ns/op	       0 B/op	       0 allocs/op
> 
> BenchmarkByReference-6   21056649	        53.82 ns/op	      96 B/op	       1 allocs/op


可以看出，当结构体通过值传递，不涉及动态分配或垃圾回收器，会更快。

为了理解原因，让我们看一下trace生成的图表。

BenchmarkByValue:
![BenchmarkByValue](/images/golang_tip_1.png "BenchmarkByValue")


BenchmarkByReference:
![BenchmarkByReference](/images/golang_tip_2.png "BenchmarkByReference")

第一张图非常简单。由于没有使用堆，因此没有垃圾收集器。

对于第二张图，指针的使用迫使go编译器将变量逃逸到堆上，并且给垃圾收集器施加压力。

总之，不要假设值传递会很慢，如果关注性能，可以使用go profiler。

## 2. 继承

Go类型系统不像C++或Java那样面向对象。Go无法真正继承结构体或接口，但可以将它们嵌套在一起以创建更复杂的结构体或接口。

> **There is** an important way in which embedding differs from subclassing. When we embed a type, the methods of that type become methods of the outer type, but when they're invoked the receiver of the method is the inner type, not the outer one. 
>
> --- https://golang.org/doc/effective_go

除了嵌入类型之外，Go还允许重新定义类型。重新定义继承类型的字段，但不继承其方法。

```golang
package main

type t1 struct {
    f1 string
}

func (t *t1) t1method() {
}

type t2 struct {
    t1
}

type t3 t1 

func main() {
    var mt1 t1
    var mt2 t2
    var mt3 t3

    // 所有case字段都能继承
    _ = mt1.f1
    _ = mt2.f1
    _ = mt3.f1

    // 正常调用
    mt1.t1method() 
    mt2.t1method()

    // mt3.t1method未定义
    mt3.t1method()
}
```

## 3. Defer语句

***defer语句将函数调用推送到列表上。保存的列表在函数返回后执行。defer通常用于简化执行各种清理操作。***

需要注意的是：

- 当函数返回时调用defer函数，在调用defer时其参数完成了赋值。

```golang
package main

import (
    "fmt"
)

func main() {
    err := errors.New("defer")
	defer fmt.Println(err)
	err = errors.New("Something happening")
	fmt.Println(err)
}
```

> Something happening
> 
> defer

- 函数返回后，defer函数按照后进先出的顺序执行。

```golang
package main

import (
    "fmt"
)

func main() {
    defer fmt.Println("one")
    defer fmt.Println("two")
    defer fmt.Println("three")
}
```

> three
> two
> one

## 4. 循环

***for循环迭代器变量会被重用***

在循环中，每次迭代都会重用同一个的索引变量和值变量。

```golang
package main

import "fmt"

func main() {
    var out []*int
    for i := 0; i < 3; i++ {
        out = append(out, &i)
    }
    fmt.Println("Values:", *out[0], *out[1], *out[2])
    fmt.Println("Addresses:", out[0], out[1], out[2])
}
```

> Values: 3 3 3
>
> Addresses: 0xc0000120e0 0xc0000120e0 0xc0000120e0

在循环中启动goroutine也是类似：

```golang
package main

import (
    "fmt"
    "time"
)

func main() {
    for i := 0; i < 3; i++ {
        go func() {
            fmt.Print(i)
        }()
    }
    time.Sleep(time.Second)
}
```

> 333

这些goroutine是在这个循环中创建的，但是运行它们需要一些时间。

变量i被goroutine使用了，所以发生了逃逸，变量i实际上是一个指针。

所以，当goroutine执行时，捕获的迭代变量i一般是最后的值。

在这种情况下，可以在代码块内创建一个新变量，或者将迭代器变量作为参数传递给goroutine。

```golang
package main

import (
    "fmt"
    "time"
)

func main() {
    for i := 0; i < 3; i++ {
        go func(i int) {
            fmt.Print(i)
        }(i)
    }
    time.Sleep(time.Second)
}

// 或者

func main() {
    for i := 0; i < 3; i++ {
        i := i
        go func() {
            fmt.Print(i)
        }()
    }
    time.Sleep(time.Second)
}

```

> 012

如果循环不是启动goroutine，二十调用一个简单的函数，则代码会按预期执行：

```golang
for i := 0; i < 3; i++ {
    func() {
        fmt.Print(i)
    }()
}

```

> 012

每个函数调用都不会让循环继续，知道函数执行结束，在这段时间将获得预期的值。

再看看一个更复杂的例子：

```golang
package main

import (
    "fmt"
    "time"
)

type myStruct struct {
    v int
}

func (s *myStruct) myMethod() {
    fmt.Printf("%v, %p\n", s.v, s)
}

func main() {
    byValue := []myStruct{{1}, {2}, {3}}
    byReference := []*myStruct{{1}, {2}, {3}}

    fmt.Println("By value")

    for _, i := range byValue {
        go i.myMethod()
    }
    time.Sleep(time.Millisecond * 100)

    fmt.Println("By reference")

    for _, i := range byReference {
        go i.myMethod()
    }
    time.Sleep(time.Millisecond * 100)
}

```

> By value
> 
> 3, 0xc000012120
> 
> 3, 0xc000012120
> 
> 3, 0xc000012120
> 
> By reference
> 
> 1, 0xc0000120e0
> 
> 3, 0xc0000120f0
> 
> 2, 0xc0000120e8

当通过引用使用myStruct时，它的运行就好像没有陷阱一样！这与Goroutine的创建方式有关。

Goroutine参数在Goroutine创建时就被赋值，方法接收者（myMethod的myStruct）实际上是一个参数。

当按值调用时：由于myMethod的参数s是指针类型，因此i的地址作为参数传递给了Goroutine。

我们知道迭代器变量会被重用，因此每次都是相同的地址。当迭代器执行时，它将把新的myStruct值复制到i变量相同的地址。打印的值时Goroutine执行时变量i的值。

当通过指针调用时：参数已经是一个指针，因此它的值在创建Goroutine时被推送到新Goroutine的栈中。

这恰好时我们想要的地址，并且打印了预期的值。


## 5. map迭代顺序并不随机

***从技术上讲，map迭代顺序是“未定义的”***

Go在内部使用哈希表完成映射，因此map的迭代通常会按照map元素在该表中的布局顺序进行。

当新元素添加到map中时，这个顺序时不可靠的，并且会随着哈希表的增长而发生变化。

```golang
package main

import "fmt"

func main() {
	m := map[int]int{0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6}
	for i := 0; i < 5; i++ {
		for i := range m {
			fmt.Print(i, " ")
		}
		fmt.Println()
	}
	m[7] = 7
	m[8] = 8
	m[9] = 9

	for i := 0; i < 5; i++ {
		for i := range m {
			fmt.Print(i, " ")
		}
		fmt.Println()
	}
}

```

> 0 1 2 3 4 5 6
> 
> 4 5 6 0 1 2 3
> 
> 0 1 2 3 4 5 6
> 
> 0 1 2 3 4 5 6
> 
> 2 3 4 5 6 0 1
> 
> 0 1 2 3 4 6 5 7 8 9
> 
> 3 4 6 0 1 2 9 5 7 8
> 
> 3 4 6 0 1 2 9 5 7 8
> 
> 6 0 1 2 3 4 5 7 8 9
> 
> 5 7 8 9 0 1 2 3 4 6

在上面的例子中，当map从1到6初始化map时，它们将按该顺序添加到哈希表中。

前五行打印的都是按顺序写入的数字，Go仅随机化从哪个元素开始迭代。

向map添加更多元素会使map的哈希表增长，从而对整个哈希表进行重新排序。最后五行打印不再具有任何明显的顺序。

## 6. map是一个指针

***在Go中map关键字是\*runtime.hmap的别名***

由于map是一个指针，因此将其作为函数入参，指向的是同一个map数据结构。

```golang
package main

import "fmt"

func f1(m map[int]int) {
    m[5] = 123 
}

func main() {
    m := make(map[int]int)
    f1(m)
    fmt.Println(m[5]) // prints 123
}

```

## 7. struct{}类型

Go没有类似c++的std:set类型。但是可以通过struct{}作为map的值代替set类型。

```golang
package main

import (
    "fmt"
)

func main() {
    m := make(map[int]struct{})
    m[123] = struct{}{}
    _, key := m[123]
    fmt.Println(key)
}

```

可能你会想到用bool类型作为map的值也未尝不可，但是实际上struct{}类型占用内存大小为零字节。

```golang
package main

import (
    "fmt"
    "unsafe"
)

func main() {
    fmt.Println(unsafe.Sizeof(false)) // 1
    fmt.Println(unsafe.Sizeof(struct{}{})) // 0
}

```

## 8. map的容量

map是一个相当复杂的数据结构。

虽然可以可以在创建时指定其初始容量，但在以后时无法获取其容量的，至少无法通过cap获取。

```golang
package main

import (
    "fmt"
)

func main() {
    m := make(map[int]bool, 5) // 初始化容量为5
    fmt.Println(len(m))        // len没问题
    fmt.Println(cap(m))        // 编译器错误，invalid argument m (type map[int]bool) for cap
}

```

## 9. map值无法寻址

Go的map是通过哈希表实现的，哈希表需要在map增长或缩小时移动元素的，因此Go不允许获取map元素的地址。

```golang

package main

import "fmt"

type item struct {
    value string
}

func main() {
    m := map[int]item{1: {"one"}}

    fmt.Println(m[1].value) 
    addr := &m[1]           // error: cannot take the address of m[1]
    m[1].value = "two"      // error: can't assign to struct field m[1].value in map
}

```

## 10. map并发安全问题

***常规的map不是并发安全的***

```golang

package main

import (
    "math/rand"
    "time"
)

func readWrite(m map[int]int) {
    for i := 0; i < 100; i++ {
        k := rand.Int()
        m[k] = m[k] + 1
    }
}

func main() {
    m := make(map[int]int)

    for i := 0; i < 10; i++ {
        go readWrite(m)
    }

    select{}
}

```

> fatal error: concurrent map read and map write
> 
> fatal error: concurrent map writes
> 
> ...


sync包中有一个特殊的map，可以安全地供多个Goroutine并发读写。

不过Go官方文档建议在大多数情况下使用带锁的常规map或协调控制，sync.Map不是类型安全的，它类似于map[interface{}]interface{}。

> The Map type is optimized for two common use cases: (1) when the entry for a given key is only ever written once but read many times, as in caches that only grow, or (2) when multiple goroutines read, write, and overwrite entries for disjoint sets of keys. In these two cases, use of a Map may significantly reduce lock contention compared to a Go map paired with a separate Mutex or RWMutex.
> --- https://github.com/golang/go/blob/master/src/sync/map.go

即
- 当给定键只被写入一次但被多次读取时，例如在仅会增长的缓存中。
- 当多个Gouroutine读取、写入和覆盖不同键的条目时。


## 11. Go字符串都是UTF-8？

***编译器或Go字符串处理代码与最终编码为UTF-8的字符串没有任何关系***

造成这种混乱的原因之一就是字符串的字面量。虽然字符串本身没有任何特定的编码，但Go编译器始终将源代码解释为UTF-8。

定义字符串字面量之后，文本编辑器会将其于代码的其余部分一样保存为UTF-8编码的Unicode字符串。这就是Go解析后将编译到程序中的内容。

下面例子，定义了非UTF-8字符串，为了证明这一点：

```golang

package main

import (
    "fmt"
    "unicode/utf8"
)

func main() {
    s := "\xc1\x2b\xa3"

	fmt.Println(utf8.ValidString(s)) // false

	fmt.Println(s) // �+�
}

```

## 12. iota从零编号？

iota在Go中以常量编号开始，但并不像某些人想象的那样从零开始，而是从当前const块中常量的索引开始：

```golang

const (
    myconst = "c"
    myconst2 = "c2"
    two = iota // 2
)

```

在当前const块中使用iota两次不会重置编号

```golang
const (
    zero = iota // 0
    one // 1
    two = iota // 2
)

```