<style>
div {
    font-size: 16px;
	line-height: 1.75em;
}

</style>
# go泛型浅析

> ## 序

*  go语言从发明之初，就以其语法简洁著称。但作为一门现代化的编程语言，缺少泛型支持在一定程度上让我们在代码编写难免出现一些重复相识的代码(有效提高了工作量)，同一个算法对不同的类型要么Copy,要么反射或者类型断言,前者增加了我们代码编写的工作量，后者增加了代码复杂性，对后续维护不利。所幸的是go泛型在经历了多次跳票之后，终于在1.18版本正式发布了,之前的旧泛型很多设计，在1.18中也被废弃或更改。在1.18版本发布后，我就马上进行了升级尝鲜，在这里对go泛型使用上的一些经验进行一下总结

> ## 代码复用之痛

*   在1.18之前的版本中，go语言还没有支持泛型的时候，标准库math.Max只能支持float64一直被人们调侃，下面这种代码也是随处可见

```go

package main
import "fmt"

func AddInt(x,y int) int{
    return x+y
}

func AddInt64(x,y int64) int64{
    return x+y
}

func AddFloat32(x,y float32)float32{
    return x+y
}

func AddFloat64(x,y float64) float64{
    return x+y
}

func SumInt(items []int)int{
    sum:=0
    for _,item:=range items {
        sum+=item
    }
    return sum
}

func SumInt64(items []int64)int64{
    sum:=int64(0)
    for _,item:=range items {
    	    sum+=item
    }
    return sum
}

func main(){
	intX:=1
	intY:=2
	int64X:=int64(1)
	int64Y:=int64(2)	
	float32X:=float32(1.1)
	float32Y:=float32(2.2)
	float64X:=float64(1.1)
	float64Y:=float64(2.2)
	sliceInt:=[]int{1,2,3,4}
	sliceInt64:=[]int64{1,2,3,4,6}
	fmt.Println(AddInt(intX,intY))
	fmt.Println(AddInt64(int64X,int64Y))
	fmt.Println(AddFloat32(float32X,float32Y))
	fmt.Println(AddFloat64(float64X,float64Y))
	fmt.Println(SumInt(sliceInt))
	fmt.Println(SumInt64(sliceInt64))
}
```
*   这些代码的算法完全相同，仅仅是其处理的数据类型不一样， 在编码上来说无疑是非常繁琐又枯燥的，维护起来也非常的麻烦，对调用者来说也没有那么友好。比如算法被测试出有bug，必须对所有使用算法的类型进行全部修改，如果部分类型的算法的代码被遗漏，就会导致潜在的遗留bug，如果需要新增加一种数据类型，又要复制一遍算法代码，这无论怎么说都不是一种好的编码体验。
*   不过在1.18版本之后，在支持泛型之后，能在很大程度上可以提升我们的编码体验与效率，增加代码复用度。比如上面的代码现在可以这样写:

```go
package main
import "fmt"

func Add[T int|int64|float32|float64](x,y T)T {
	return x+y
}

func Sum[T int|int64](items []T)T{
   var sum T
   for _,item:=range items{
	   sum+=item
   }
   return sum
}

func main(){
	intX:=1
	intY:=2
	int64X:=int64(1)
	int64Y:=int64(2)	
	float32X:=float32(1.1)
	float32Y:=float32(2.2)
	float64X:=float64(1.1)
	float64Y:=float64(2.2)
	sliceInt:=[]int{1,2,3,4}
	sliceInt64:=[]int64{1,2,3,4,6}
	fmt.Println(Add(intX,intY))
	fmt.Println(Add(int64X,int64Y))
	fmt.Println(Add(float32X,float32Y))
	fmt.Println(Add(float64X,float64Y))
	fmt.Println(Sum(sliceInt))
	fmt.Println(Sum(sliceInt64))
}
```

*   &#x20;这前后两个例子一对比，能明显的看到在使用泛型之后，代码量少了(简洁了?)，算法能得以复用，对提高代码可维护性，API使用友好性都有很大帮助。

> ## 泛型概念

- Grammar (语法形式)
     ```
    TypeParameters  = "[" TypeParamList [ "," ] "]" .
     ```
    - 这里我们从Go语言规范上摘抄了泛型的语法定义,从中可以直观的看出泛型定义就是一对中括号加上泛型形参列表及一个可选的用于换行的逗号.
    - 我们写一些简单的类型定义
    ```go
        // generic function
        func Add[T int|int32](x,y) T{
            return x+y
        }
        
        func CastSlice[T,V any](s []T,conv func(T)V)[]V{
            targets:=[]V{}
            
            for _,item:=range s{
                targets=append(targets,conv(item)
            }
            
            return targets
        }
        
        // generic struct
        
        type List[T int|int32] struct{
            items []T
        }
        
        type LinkedList[T int|int32] struct{
            head LinkedNode[T]
            tail LinkedNode[T]
        }zz
        
        // generic interface
        type ICollection[T comparable] interface{
            Count() int
            Add(item T)
            Remove(item T)
        }
    ```

- Type parameter list(类型形参列表)
    ```
    TypeParamList   = TypeParamDecl { "," TypeParamDecl } .
    ```
    ```go
    func Cast[T,V any](items []T,conv func(T)V) []V{
        targets:=[]V{}
        
        for _,item:=range items{
            targets=append(targets,conv(item)
        }
        
        return targets
    }
    ```
    - 从语法的来看,泛型形参列表就是由一个或多个泛型形参定义组成,从上面的代码来看中括号内部的内容组成就是一个泛型形参列表.
    
- Type parameter declaration(类型形参定义)
    ```Go
    TypeParamDecl   = IdentifierList TypeConstraint .
    IdentifierList  = identifier { "," identifier }
    // 展开
    TypeParamDecl   =  identifier { "," identifier } TypeConstraint .
    ```
    
    ```Go
    func Add[T int|float32](x,y T)T {
        // 
    }
    
    func Cast[T any,V any](x T)V {
        //
    }
    
    func Cast[T,V any](x T)V {
        //
    }
    
    ```
    
    - 泛型形参定义即是有标识符列表加上类型约束组成,我们将语法展开更加直观的可以看出泛型形参定义就是一个或多个标识符加上类型约束组成,与我们普通函数形参定义的语法形式相同. 上面代码中的`T`、`V`表示泛型形参的名字,`any`、`int|float32`即使类型约束.

- Type constraint(类型约束)
   ```
    TypeConstraint = interface{E}
   ```
   - 类型约束是定义相应类型形参的支持类型范围.如 `T int|int32` 就约束`T`的类型只能是`int`或`int32`,一个完整的类型约束定义应该是`interface{E}`,`E`是类型的名称.比如`interface{int|int32|string}`,不过`interface{}`一般情况下都可以省略.
   - 下面我们看一些例子
   ```go
      type interface Stringer {
          string String()
      }
      
      // 泛型函数
      func Add[T interface{int}](x,y T)T{
          return x+y
      }
      
      func Add[T int|float32](x,y T) T {
          return x+y
      }
      
      func Add[T *int](x,y T)T{
         v:=*x+*y
         return &v
      }
      
      func Print[T Stringer](s T){
          println(s.String())
      }
      
      type NumberSlice[T int|float32] []T
      
      type StringSlice[T string|Stringer] []T
   ```
   - 在泛型类型定义中,当类型约束是指针时, interface不能省略,否则会编译失败
   ```
     type PtrSlice[T interface{*int|*float32}] []T 
   ```
   - ~符号用于表示只要是兼容的底层基础类型,只能用于基础类型
   ```go
      type Int int
      type Float32 float32
      type Slice[T ~int|float32] []T
      type Slice2[T int|float32] []T 
      
      func main(){
        var s1 Slice[int]       // ok
        var s2 Slice[Int]       // ok
        var s3 Slice[float32]   // ok
        var s4 Slice[Float32]   // error
        var s5 Slice2[int]      // ok
        var s6 Slice2[Int]      // error
      }
   ```
    
- Type argument(类型实参)
    ```Go
    func Add[T int|float64] (x,y T) T{
        return x+y    
    }
    
    func main(){
        Add[int](1,2)               // ok
        Add[float64](1.1,2.2)       // ok 
        Add(1,2)                    // ok   
        Add(1,1.2)                  // error 
        Add[float64](1,1.2)         // ok
    }
    ```
    - 我们对前面定义的Add函数进行一些调用,如上面的代码`Add[int]`及`Add[int32`],其中`[]`中的`int`及`float64`就是类型实参,它将具体的类型传递给Add函数的类型形参`T`. 对于泛型函数类型实参,如果编译器能推导出类型实参时,可以从左到右省略类型实参,否则就必须传递类型实参,而对于泛型类型则不能省略.

- Instantiations(实例化)
    - 实例化泛型类型会生成新的非泛型命名类型;实例化泛型函数会生成一个新的非泛型函数。
    - 泛型函数或泛型类型过用类型实参传入类型形参来实例化的.每个类型实参必须实现相应类型形参的约束.否则,实例化将失败.简单来说就是通过传入泛型类型实参来确定应该生成具体类型.
    ```
    func main(){
        var s Slice[int] // 实例化一个一个泛型参数为int的Slice,其具体类型是Slice[int]
        var add Add[int] // 实例化一个一个泛型参数为int的Add函数,其具体类型为 func Add[int](x,y int)int
    }
    ```

> # 内置类型
- comparable & any
	- 在1.18中go语言引入了两个内置接口类型(严格来说只有`comparable`,`any`是`interface{}`的别名),`any`表示可以接收任意类型.`comparable`表示可比较的,即该类型必须支持`==`与`!=`操作,而且`comparable`只能用于约束泛型形参参数,不能用于其他地方.
	```go
	func SliceToMap[S any,K comparable,V any](s []T,k func(S)K,v func(S)V)map[K]V{
		m:=map[K]T{}
		for _,item:=range s{
			m[k(item)]=v(item)
		}

		return v
	}
	```
	- 上面的代码中,我们编写了一个讲任意`slice`转换为`map`的函数,因为`map`的`key`必须是要支持可比较的,所以我们可以用`comparable`对`key`进行约束.

- constraints包 (golang.org/x/exp/constraints)
   - constraints包提供了一些定义好的接口(挺少的),在开发过程中我们可以直接进行使用.
   ```go
	type Complex interface {
		~complex64 | ~complex128
	}

	type Float interface {
		~float32 | ~float64
	}

	type Integer interface {
		Signed | Unsigned
	}

	type Ordered interface {
		Integer | Float | ~string
	}

	type Signed interface {
		~int | ~int8 | ~int16 | ~int32 | ~int64
	}

	type Unsigned interface {
		~uint | ~uint8 | ~uint16 | ~uint32 | ~uint64 | ~uintptr
	}
   ```

> 练习
	- 我们来写用泛型实现一个`List`(类似于`C#`中的`List<T>`)来练习一下泛型得使用及一些小技巧.
	```go
	// type definition
	
	type List[T any] interface {
		Get(index int)T
		Set(value T,index int)
		Empty() bool
		Count() int
		Slice() []T
		Contains(item T) bool
		Find(filter func(item T) bool) List[T]
		First(filter func(item T) bool) (T, bool)
		FirstOrDefault(filter func(item T) bool) T
		Add(item T)
		Insert(item T, index int)
		IndexOf(item T) int
		Remove(item T) bool
		RemoveAll(filter func(item T) bool) bool
	}
	```
	- 我们先定义一下这个`List`的`interface`,下面我们来定义一下它的实现
	```go
	type List[T any] struct{
		items []T
	}
	```
	- 这个`struct`的结构非常简单,它内部引用一个`slice`来存储具体的数据
	- NewList 函数,很简单,没什么好说的
	```go
	func NewList[T any]() *List[T] {
		return &List[T]{
			items: make([]T, 0),
		}
	}
	```
	-  Get|Set方法
	```go
	func (list *List[T]) Get(index int) T {
		if index < 0 || index >= list.Count() {
			panic("index out of slice range")
		}

		return list.items[index]
	}

	func (list *List[T]) Set(value T, index int) {
		if index < 0 || index >= list.Count() {
			panic("index out of slice range")
		}

		list.items[index] = value
	}

	```
	-  Empty|Count|Slice方法
	```go
	func (list *List[T]) Empty() bool {
		return len(list.items) == 0
	}

	func (list *List[T]) Count() int {
		return len(list.items)
	}

	func (list *List[T]) Slice() []T {
		return list.items[:]
	}
	```
	- IndexOf | Contains 方法
	```go
	func (list *List[T]) IndexOf(item T) int {
		for index, it := range list.items {
			if it==item {  // error invalid operation: it == item (type parameter T is not comparable with ==)
				return index
			}
		}

		return -1
	}

	func (list *List[T]) Contains(item T) bool {
		return list.IndexOf(item) >= 0
	}
	```
  	- 很快写出来了，可惜编译失败，因为我们这个泛型形参不是可比较的，怎么办呢.有很多种办法
  		- 修改泛型形参约束类型为`comparable`,但是这个就直接限制了我们`List`的可用范围.
  		- 修改`IndexOf`方法参数,像`First`方法那样传递一个`func`,因为调用的时候泛型类型已经实例化好了,调用方可以进行比较,但每一次调用都需要额外传递参数
  		- `NewList`增加参数传递一个`func`或`interface`,存到`List`内部,我比较倾向于这种
  	- 我们修改一下`List`的定义及重新实现一下`NewList`方法
  	```go
  	type List[T any] struct {
		items []T
		comp  func(x, y T) int
	}

	func NewList[T any](comp func(x, y T) int) *List[T] {
		return &List[T]{
			comp:  comp,
			items: make([]T, 0),
		}
	}

  	func (list *List[T]) IndexOf(item T) int {
  		for index, it := range list.items {
  			if list.comp(it,item)==0 {
  				return index
  			}
  		}

  		return -1
  	}
  	```
	- Find|First|FirstOrDefault 方法
	```go
	func (list *List[T]) Find(filter func(T) bool) *List[T] {
		n := NewList[T](list.comp)
		for _, item := range list.items {
			if filter(item) {
				n.Add(item)
			}
		}

		return n
	}

	func (list *List[T]) First(filter func(T) bool) (T, bool) {
		for _, item := range list.items {
			if filter(item) {
				return item, true
			}
		}

		var v T
		return v, false
	}

	func (list *List[T]) FirstOrDefault(filter func(T) bool) T {
		v, _ := list.First(filter)
		return v
	}

	```
	- Add|Insert|Remove|RemoveAll方法
	```go
	func (list *List[T]) Add(item T) {
		list.items = append(list.items, item)
	}

	func (list *List[T]) Insert(item T, index int) {
		if index == 0 {
			list.items = append([]T{item}, list.items...)
			return
		}

		if index == list.Count()-1 {
			list.Add(item)
			return
		}

		if index < 0 || index >= list.Count() {
			panic("index out of slice range") // error
		}

		list.items = append(list.items[0:index], append([]T{item}, list.items[index:]...)...)
	}
		
	func (list *List[T]) Remove(item T) bool {
		index := list.IndexOf(item)
		if index < 0 {
			return false
		}

		if index == list.Count()-1 {
			list.items = list.items[0:index]
		} else {
			list.items = append(list.items[0:index], list.items[index+1:]...)
		}

		return true
	}

	func (list *List[T]) RemoveAll(filter func(item T) bool) bool {
		var (
			ok    bool
			items []T
		)

		for index, item := range list.items {
			if !filter(item) {
				if ok {
					items = append(items, item)
				}
			} else {
				ok = true
				items = list.items[0:index]
			}
		}

		if ok {
			list.items = items
		}

		return ok
	}

	```
	- 测试
	```go
	type User struct{
		ID int
		Name string
	}

	func Compare[T constraints.Integer](x, y T) T {
		return x - y
	}

	func main() {
		s := NewList(Compare[int])
		s.Add(1)
		s.Add(2)
		s.Add(3)
		s.Add(4)
		println(s.Contains(1))
		println(s.Contains(10))
		println(s.Find(func(item int) bool { return item%2 == 0 }).Count())

		users:=NewList(func(x,y User)int{
			return x.ID-y.ID
		})

		users.Add(User{ID:1,Name:"张三"})
		println(users.Contains(User{ID:1,Name:"张三"}))
	}

	// outputs
	// true
	// false
	// 2
	// true
	```
> 吐槽
	- 我们想扩展上面的`List`,比如我们增加如下将`List`转换为`map`的方法
	```Go
	func (list *List[T]) AsMap[TKey comprable](k func(item intT)TKey) map[TKey,T] {
		// syntax error: method must have no type parameters
		return nil
	}
	```
	- 按照`java`或`c#`等其他语言的经验,我们很容易写出如上代码定义,可是go语言目前并不支持泛型方法,将来会支持泛型方法.上面的代码直接编译失败.
	- 那么目前我们该,怎么办? 
	- 我们想到既然不支持泛型方法,但是他支持泛型函数,所以我们可以改成这样
	```Go
	func AsMap[T any,TKey comprable](list List[T],k func(item T)TKey) map[TKey] {
		// syntax error: method must have no type parameters
		return nil
	}
	```
	- 这样就行了,使用时直接`m:=AsMap(list,func(item User)int{return user.ID})`
    
	```Go 
	type ListComp [T any,TKey comparable] List[T]

	func (list *ListComp[T,TKey]) AsMap(k func(item T)TKey) map[TKey] {
		// 
	}

	func main(){
		list:=NewList(Compare[int]);
		listK:=(*ListComp[int,string])(list)
		listK.AsMap(func(item int)string{return fmt.Sprintf("%d",item)})
	}
	```
	- 虽然通过定义一个中介类型,在中介类型上添加新的类型参数,可以达到扩展泛型方法的目的,但是使用上要涉及到来会的强制类型转换,还是等后续版本支持泛型方法吧.
