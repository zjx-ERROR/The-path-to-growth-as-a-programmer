---
title: "Golang技巧"
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


