package main

import (
	"fmt"

	"golang.org/x/exp/constraints"
)

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

func (list *List[T]) Empty() bool {
	return len(list.items) == 0
}

func (list *List[T]) Count() int {
	return len(list.items)
}

func (list *List[T]) Slice() []T {
	return list.items[:]
}

func (list *List[T]) Find(filter func(T) bool) *List[T] {
	n := NewList(list.comp)
	for _, item := range list.items {
		if filter(item) {
			n.Add(item)
		}
	}

	return n
}

func (list *List[T]) IndexOf(item T) int {
	for index, it := range list.items {
		if list.comp(it, item) == 0 {
			return index
		}
	}

	return -1
}

func (list *List[T]) Contains(item T) bool {
	return list.IndexOf(item) >= 0
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

type User struct {
	ID   int
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

	users := NewList(func(x, y User) int {
		return x.ID - y.ID
	})

	users.Add(User{ID: 1, Name: "张三"})
	println(users.Contains(User{ID: 1, Name: "张三"}))
}
