# modelite.js

轻量级双向数据绑定工具。

## 特点

1. **简单**
2. **轻量**
3. **持久**

## 安装

```html
<script src="modelite.min.js"></script>
```

_* 需要 jQuery 库。_

## 快速入门

无需编写任何代码，将 DOM 元素的 `name` 属性和数据名对应，就可以完成绑定。
DOM 的层次关系也就是数据对象的层次。

```html
    <form name="data">
        <input type="text" name="name">
        <input type="text" name="age">
        <input type="text" name="gender">
    </form>

    Name: <span name="data.name"></span>
```

在内存中储存的数据为：

```json
{
    "data": {
        "name": "",
        "age": "",
        "gender": ""
    }
}
```

## 选项属性

对 DOM 元素使用以下 `ml-` 属性可以实现对数据的简单操作和显示控制。

属性 | 类型 | 默认值 | 说明
----|----|----|----
`default` | `String` | `null` | 数据的默认值。
`placeholder` | `String` | `null` | 数据为空值时标签元素上可以显示的值，该值不储存。
`reserve` | `Number` | `0` | 对于 `Array` 类型的数据，必须保留的数据数量，不足时用默认值填充。
`repeat` | `String` | `all` | 循环模版标签元素时，控制模版显示的方式，可选择值：`header`，`footer`，`body`，`odd`，`even` 和 `all`，，使用详见后文。
`insert` | `String` | `null` | 插入动作，往 `Array` 中插入新数据，使用详见后文。
`remove` | `String` | `null` | 删除动作，删除 `Array` 中的数据，使用详见后文。
`events` | `String` | `null` | 触发的事件，使用详见后文。

实例：

```html
    <span name="name" ml-default="Kan"></span>
```

```html
    <img name="avatar" ml-placeholder="https://avatars1.githubusercontent.com/u/1096425">
```

```html
    <button ml-remove="list.0"></button>
```

## 数据

所有数据都存储在内存中，可以通过 `ml.DATA =` 初始化默认的数据，初始化必须在 `$(ready)` 调用之前完成。
初始化的数据会在页面加载完成后立即显示出来。

## 事件

兼容所有原生 DOM 事件，通过 DOM 元素的 `ml-events=` 属性设置事件，事件的设置方式：

```
ml-events="(eventType)eventName:args...; (eventType)eventName:args...; ..."
```

eventType | 事件类型 | 兼容所有 DOM 原生事件类型。
eventName | 事件名称 | 事件触发调用的函数，所有的调用函数都在 `ml.EVENTS` 对象中，
args | 用户参数 | 参数是通过 `event.data` 对象传递给调用函数的数据，参数值类型都是 `String`。参数接受两种形式传递：`argv1 [,argv2]...` 或 `key1=value1 [,key2=value2]...`。

实例：

```html
    <button ml-events="(click)buttonClick:Bazinga"></button>
```

```js
ml.EVENTS = {
    buttonClick: function(event) {
        alert(event.data);  /* show: Bazinga */
    }
}
```

### 扩展事件类型

除了原生事件，还补充了以下几个事件类型：

事件类型 | 事件参数 | 说明
----|----|----
`insert` | `keypath` | 当 `ml-insert` 插入动作完成后触发该事件，使用详见后文。
`remove` | `keypath` | 当 `ml-remove` 删除动作完成后触发该事件，使用详见后文。
`repeat` | `length` | 当循环结束后触发该事件，使用详见后文。
`each` | `index` | 当循环的每个元素插入后触发该事件，使用详见后文。

_*`ml-insert` 插入动作完成后会触发 `insert` 事件和 `each` 事件，因为插入的 `Array` 元素也是循环当中的一个元素，详见后文。_

## 循环

将 DOM 元素（及其子元素）指定为模版，绑定的 `Array` 类型数据的每一个值都会用该模版显示出来。
指定为模版的 DOM 元素只需要用 `#` 作为 `name` 属性的值，并且将该元素包裹在绑定对应 `Array` 类型数据的父元素内。

```html
    <div name="people">
        <p name="#">
            <span name="name"></span>
            <span name="age"></span>
        </p>
    </div>
```

在内存中储存的数据为：

```json
{
    "people": [
        {
            "name": "",
            "age": ""
        }
    ]
}
```

如果模版子元素的 `name` 属性值为 `$`，则可以用来表示直接将使用数组元素的值。

```html
    <div name="people">
        <div name="#">
            <p name="$"></p>
        </div>
    </div>
```

### 循环选项

通过 `ml-reserve` 和 `ml-repeat` 两个选项来控制数据显示的方式。

如果需要在显示时候指少保留 `n` 个默认项，则使用 `ml-reserve="n"` 来设置保留项的个数。`ml-reserve` 必须在循环的父元素属性中设置。

```html
    <select name="list" ml-reserve="1">
        <option name="#"></option>
    </select>
```

如果要控制模版在循环时特定时候显示或隐藏，则使用 `ml-repeat="header|footer|body|odd|even|all"` 来控制只在设定的状态下才显示。

* `header` 循环第一次显示
* `footer` 循环最后一次显示
* `body` 非循环的第一次或最后一次显示
* `odd` 奇数次循环显示
* `even` 偶数次循环显示
* `all` **默认值**，始终显示。

```html
    <div name="people">
        <div name="#">
            <p ml-repeat="header">Name: Age</p>
            <p>
                <span name="name"></span>:
                <span name="age"></span>
            </p>
            <p ml-repeat="footer">End</p>
        </div>
    </div>
```

### 循环事件

#### `each:keypath`

当循环进行中，模版被成功处理完一次，都会触发一次 `each` 事件，事件参数为当前绑定数据的 `keypath`。

```html
    <select name="list">
        <option name="#" ml-events="(each)listEach"></option>
    </select>
```

```js
ml.DATA = {
    list: ["zero", "one", "two"]
}
ml.EVENTS = {
    listEach: function(event, keypath) {
        console.log(keypath + ": " + ml(keypath));
    }
}
/*
list.0: zero
list.1: one
list.2: two
*/
```

#### `repeat:length`

循环全部结束后，将会触发 `repeat` 事件，事件参数为当前绑定的 `Array` 类型数据的 `length`。

```html
    <select name="list" ml-events="(each)listRepeat">
        <option name="#"></option>
    </select>
```

```js
ml.DATA = {
    list: ["zero", "one", "two"]
}
ml.EVENTS = {
    listRepeat: function(event, length) {
        console.log("list.length: " + length);
    }
}
/*
list.length: 3
*/
```

## 动作

依据循环的模版对绑定的 `Array` 类型数据执行插入（`ml-insert`）和删除（`ml-remove`）操作，新插入的值均使用模版中定义的默认数据。

插入和删除动作的属性值为绑定数据的 `keypath`，如果 `keypath` 中不包含 `index`，则默认为最后一项。

```html
    <select name="list">
        <option name="#" ml-default="0"></option>
    </select>
    <button ml-insert="list">Add</button>
    <button ml-insert="list.0">Remove</button>
```

如果 `keypath` 中包含 `#`，则会自动替换成当前模版的 `index` （使用在模版的子元素上才有效）。

```html
    <div name="people">
        <p name="#">
            <span name="name"></span>
            <span name="age"></span>
            <button ml-remove="people.#">Delete</button>
        </p>
    </div>
```

### 动作事件

插入和删除动作完成后，都会触发对应的事件（`insert` 和 `remove`），事件参数为当前绑定数据的 `keypath`。

```html
    <button ml-insert="list" ml-events="(insert)listAdded">Add</button>
    <button ml-remove="list.0" ml-events="(insert)listRemoved">Add</button>
```

```js
ml.EVENTS = {
    listAdded: function(event, keypath) {
        console.log("added: " + keypath);
    },
    listRemoved: function(event, keypath) {
        console.log("removed: " + keypath);
    }
}
```

## APIs
### `ml(keypath [,value])`

获取或设置绑定的 `keypath` 数据的 `value`。

```js
ml("data.name.first", "Kan");
/*
{
    "data": {
        "name": {
            "first": "Kan"
        }
    }
}
*/
```

### `ml.clear(keypath)`

清除绑定的 `keypath` 数据。

```js
ml.clear("data.name");
/*
{
    "data": {}
}
*/
```

### `ml.insert(keypath, value)`

向绑定的 `Array` 类型的 `keypath` 数据插入新 `value`，`keypath` 中如果没有指定 `index` 则默认插入到最后一个元素。

```js
ml.insert("list", "new");
/*
{
    list: ["old", "new"]
}
*/
ml.insert("list.1", "one");
/*
{
    list: ["old", "one", "new"]
}
*/
```

### `ml.remove(keypath)`

从绑定的 `Array` 类型的 `keypath` 数据删除一个元素，`keypath` 中如果没有指定 `index` 则默认删除最后一个元素。

```js
ml.remove("list");
/*
{
    list: ["old", "one"]
}
*/
ml.remove("list.0");
/*
{
    list: ["one"]
}
*/
```

### `ml.emit(keypath, eventType)`

通过绑定数据的 `keypath` 查询 DOM 元素，然后手动触发 `eventType` 类型事件。

### `ml.emit(eventName [,eventArgs...])`

手动触发 `eventName` 事件，并且传递事件参数表 `eventArgs...`。

```js
ml.EVENTS = {
    buttonClick: function(event, arg) {
        alert(arg); /* show: Bello */
    }
}
ml.emit("buttonClick", "Bello");

```

### `ml.DATA = {...}`

初始化绑定的数据。

### `ml.EVENTS = {...}`

初始化所有事件触发调用的函数。


---

The MIT License (MIT)

Copyright (c) 2015 Kan Kung-Yip

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
