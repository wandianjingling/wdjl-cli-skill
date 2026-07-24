> 本文档是 [SKILL.md](./SKILL.md) 的配套参考文档，包含上货配置参数的详细说明。
> 仅在处理 `config set/get` 相关操作时需要读取本文档。

## 上货配置参数参考

上货配置通过 `config set <KEY> <VALUE>` 命令设置，KEY 即配置键名，VALUE 为 JSON 字符串（复杂类型）或简单值（布尔/数字/字符串）。

> **设置复杂类型时**：PowerShell 中传 JSON 需用单引号包裹或转义双引号，建议优先用简单类型配置项，复杂 JSON 在 PowerShell 中易出编码或引号问题。

```
wdjlcli config set <KEY> <VALUE> --shopid <店铺ID>
```

---

### A. 商品过滤配置

#### `FilterBasic` — 基础过滤

过滤不符合条件的商品（满足任一条件即过滤）。

| 字段 | 类型 | 说明 |
|------|------|------|
| `Copyed` | bool | 过滤已复制过的商品 |
| `HasBrand` | bool | 过滤有品牌的商品 |
| `Customized` | bool | 过滤定制商品 |
| `No7Return` | bool | 过滤不支持7天无理由退货的商品 |
| `TitleWithProhibitedWords` | bool | 过滤标题含禁用词的商品 |
| `PreSale` | bool | 过滤预售商品 |
| `NoFreeShipping` | bool | 过滤不包邮商品 |
| `NoEncryptOrder` | bool | 过滤不支持密文下单的商品 |
| `NoOnePSale` | bool | 过滤不支持一件代发的商品 |
| `NoVideo` | bool | 过滤没有视频的商品 |

```
# 示例：过滤有品牌、预售、不包邮的商品
wdjlcli config set FilterBasic {"Copyed":true,"HasBrand":true,"PreSale":true,"NoFreeShipping":true} --shopid <店铺ID>
```

---

#### `FilterKeyword` — 关键词过滤

过滤标题/品牌/类目/店铺名/发货地含有指定关键词的商品。子字段（`Brand`/`Title`/`CategoryName`/`ShopName`/`Location`）结构相同：

| 字段 | 类型 | 说明 |
|------|------|------|
| `Enabled` | bool | 是否启用此项过滤（默认 true） |
| `Keywords` | string[] | 关键词列表 |

```
wdjlcli config set FilterKeyword {"Title":{"Enabled":true,"Keywords":["旗舰店","品牌"]},"Brand":{"Enabled":true,"Keywords":["nike","adidas"]}} --shopid <店铺ID>
```

---

#### `FilterAttrs` — 属性过滤

过滤包含指定属性值的商品，格式：`属性名=属性值`，多个用逗号分隔。

```
wdjlcli config set FilterAttrs 材质=陶瓷,颜色=红色 --shopid <店铺ID>
```

---

#### `FilterGoodsPriceStock` — 商品价格库存过滤

| 字段 | 类型 | 说明 |
|------|------|------|
| `PriceLessThan` | decimal? | 过滤价格 ≤ 此值的商品 |
| `PriceGreaterThan` | decimal? | 过滤价格 ≥ 此值的商品 |
| `TotalStockLessThan` | int? | 过滤总库存 < 此值的商品 |
| `TotalStockGreaterThan` | int? | 过滤总库存 > 此值的商品 |

```
wdjlcli config set FilterGoodsPriceStock {"PriceLessThan":5,"PriceGreaterThan":9999,"TotalStockLessThan":10} --shopid <店铺ID>
```

---

#### `FilterNoImgSku` — 过滤无图SKU

```
wdjlcli config set FilterNoImgSku true --shopid <店铺ID>
```

---

#### `FilterSkuValueKeyword` — SKU规格值过滤

过滤规格值含有指定关键词的SKU，结构：`{"Enabled": bool, "Keywords": string[]}`。

```
wdjlcli config set FilterSkuValueKeyword {"Enabled":true,"Keywords":["预售","定制"]} --shopid <店铺ID>
```

---

#### `FilterSkuPriceStock` — SKU价格库存过滤

| 字段 | 类型 | 说明 |
|------|------|------|
| `PriceLessThan` | decimal? | 过滤SKU价格 ≤ 此值 |
| `PriceGreaterThan` | decimal? | 过滤SKU价格 ≥ 此值 |
| `SkuStockLessThan` | int? | 过滤SKU库存 < 此值 |
| `SkuStockGreaterThan` | int? | 过滤SKU库存 > 此值 |
| `MiniPriceSku` | bool | 是否过滤最低价SKU |

```
wdjlcli config set FilterSkuPriceStock {"PriceLessThan":1,"SkuStockLessThan":5} --shopid <店铺ID>
```

---

### B. 商品基础配置

#### `Category` — 类目配置

| 字段 | 类型 | 说明 |
|------|------|------|
| `CategoryType` | int | 0=智能匹配（默认），1=手动选择 |
| `CustomCategories` | 数组 | CategoryType=1 时必填，各平台手动类目 |

> 建议通过 `wdjlcli config set cat.manual --shopid <店铺ID>` 交互式选择类目，而非手动构造 JSON。

---

#### `Brand` — 品牌配置

| 字段 | 类型 | 说明 |
|------|------|------|
| `BrandMode` | int | 0=自动（使用上家品牌），1=无品牌（默认），2=不设置，3=自定义 |
| `UseNoBrand` | bool | 品牌匹配失败时设为无品牌（默认 true） |
| `BrandWord` | string? | 自定义品牌名（BrandMode=3 时填写） |

```
wdjlcli config set Brand {"BrandMode":1,"UseNoBrand":true} --shopid <店铺ID>
```

---

#### `GoodState` — 商品上架状态

| 字段 | 类型 | 说明 |
|------|------|------|
| `GoodState` | int | 0=立即上架，1=放入仓库（默认），2=草稿箱，3=定时上架 |
| `ToSaleTime` | DateTime? | 定时上架时间（GoodState=3），格式：`2026-06-01T10:00:00` |

```
wdjlcli config set GoodState {"GoodState":1} --shopid <店铺ID>
```

---

#### `GoodsCode` — 商家编码

| 字段 | 类型 | 说明 |
|------|------|------|
| `CodeType` | int | 0=自定义，1=上家商家编码/无则用ID（默认），2=上家商家编码/无则留空，3=上家货号/无则用ID，4=上家货号/无则留空，5=上家ID，6=不设置 |
| `CusttomCode` | string? | 自定义编码（CodeType=0） |
| `AddPrefix` | string? | 添加前缀 |
| `AddSuffix` | string? | 添加后缀 |

---

#### `GoodsNum` — 货号配置

| 字段 | 类型 | 说明 |
|------|------|------|
| `NumType` | int | 0=上家货号/无则用ID（默认），1=上家货号/无则留空，2=上家ID，3=平台+货号，4=平台+货号+批发价，5=平台+上家ID，6=平台+上家ID+批发价，7=自定义，8=随机，9=空 |
| `AddPrefix` | string? | 添加前缀 |
| `AddSuffix` | string? | 添加后缀 |
| `CusttomValue` | string? | 自定义值（NumType=7） |

---

#### `UpIntervalSeconds` — 上货间隔秒数

```
wdjlcli config set UpIntervalSeconds 5 --shopid <店铺ID>
```

---

#### `ReduceType` — 减库存类型

```
wdjlcli config set ReduceType 1 --shopid <店铺ID>
# 1=拍下减库存，2=付款减库存（默认）
```

---

### C. 标题配置

#### `TitleReBuild` — 重新生成标题

使用分词库随机打乱重组标题。

```
wdjlcli config set TitleReBuild true --shopid <店铺ID>
```

---

#### `TitleClearOption` — 标题清除配置

| 字段 | 类型 | 说明 |
|------|------|------|
| `RemoveTitileKeyword` | string? | 删除指定关键词，多个以 `\n` 分隔 |
| `ClearEn` | bool | 去除英文 |
| `ClearNum` | bool | 去除数字 |
| `ClearSpace` | bool | 去除空格 |
| `ClearEnsymbol` | bool | 去除英文符号 |
| `ClearGoodsNum` | bool | 去除货号 |
| `ClearBrackets` | bool | 去除括号 |
| `ClearComma` | bool | 去除逗号 |

```
wdjlcli config set TitleClearOption {"RemoveTitileKeyword":"限时\n促销","ClearEn":true,"ClearSpace":true} --shopid <店铺ID>
```

---

#### `TitleAddPrefixs` — 标题前缀（随机选一）

```
wdjlcli config set TitleAddPrefixs ["新款","爆款","热销"] --shopid <店铺ID>
```

---

#### `TitleAddSuffixs` — 标题后缀（随机选一）

```
wdjlcli config set TitleAddSuffixs ["包邮","特惠"] --shopid <店铺ID>
```

---

#### `TitleReplaceKeyword` — 标题替换关键词

Key=源词，Value=替换词（替换为空字符串即为删除）。

```
wdjlcli config set TitleReplaceKeyword {"正品":"","特价":"优惠"} --shopid <店铺ID>
```

---

#### `TitleLengthLimit` — 标题长度限制

0=平台默认限制，≥1=自定义长度上限。

```
wdjlcli config set TitleLengthLimit 60 --shopid <店铺ID>
```

---

#### `ShortTitle` — 短标题配置

| 字段 | 类型 | 说明 |
|------|------|------|
| `ShortTitleType` | int | 0=不设置（默认），1=使用上家短标题，2=自动生成，3=自定义 |
| `IsFirstUseSource` | bool | 优先使用源商品短标题 |
| `CusutomShortTitle` | string | 自定义短标题（ShortTitleType=3） |

```
wdjlcli config set ShortTitle {"ShortTitleType":1,"IsFirstUseSource":true} --shopid <店铺ID>
```

---

### D. 属性配置

#### `AttrAutoFillRequired` — 自动补齐必填属性

```
wdjlcli config set AttrAutoFillRequired true --shopid <店铺ID>
```

---

#### `ModifyAttrs` — 固定/修改属性值

Key=属性名，Value=`{"AttrValue": string, "ApplyMode": int}`。

| ApplyMode | 说明 |
|-----------|------|
| 0 | 匹配不上时应用（默认） |
| 1 | 强制应用 |

```
# 示例：材质匹配不上时设为纯棉，风格强制设为简约
wdjlcli config set ModifyAttrs {"材质":{"AttrValue":"纯棉","ApplyMode":0},"风格":{"AttrValue":"简约","ApplyMode":1}} --shopid <店铺ID>
```

---

#### `RemoveAttributeKeyword` — 清除属性值关键字

```
wdjlcli config set RemoveAttributeKeyword {"Enabled":true,"Keywords":["产地","品牌"]} --shopid <店铺ID>
```

---

#### `AttrReplacKeyword` — 属性值替换关键词

Key=源文字，Value=替换后文字。

```
wdjlcli config set AttrReplacKeyword {"旧值":"新值"} --shopid <店铺ID>
```

---

#### `ClearAttrNames` — 删除属性名列表

多个属性名用逗号分隔。

```
wdjlcli config set ClearAttrNames 品牌,产地 --shopid <店铺ID>
```

---

#### `AttrNameMatchMap` — 上下游属性名映射

Key=上游属性名，Value=下游属性名。

```
wdjlcli config set AttrNameMatchMap {"颜色分类":"颜色","尺码":"尺寸"} --shopid <店铺ID>
```

---

### E. 价格配置

#### `PriceSource` — 价格源

```
wdjlcli config set PriceSource 2 --shopid <店铺ID>
# 1=折扣价/批发价，2=代发价/原价（默认）
```

---

#### `PriceHandle` — 价格处理

| 字段 | 类型 | 说明 |
|------|------|------|
| `PriceMode` | int | 0=不处理（默认），1=统一价，2=按货源价加价 |
| `FixedPrice` | decimal? | 统一价金额（PriceMode=1） |
| `PriceItem` | 对象 | 加价参数（PriceMode=2），见下 |
| `SkuMiniPriceItem` | 对象? | SKU最低价单独加价参数（可选） |
| `DecimalsMode` | int? | 1=抹零，2=四舍五入1位，3=四舍五入2位（默认），4=固定尾数 |
| `FixedDecimalsValue` | decimal? | 固定尾数值（DecimalsMode=4，如0.99） |

**PriceItem 字段**（支持两步加价操作）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `Operator1Mode` | int? | 0=加金额，1=加百分比，2=乘，3=除，4=减金额 |
| `Operator1Value` | decimal? | 第一步操作数值 |
| `Operator2Mode` | int? | 第二步操作类型（同上，可选） |
| `Operator2Value` | decimal? | 第二步操作数值 |

```
# 示例：货源价×1.3再+5元，小数四舍五入2位
wdjlcli config set PriceHandle {"PriceMode":2,"PriceItem":{"Operator1Mode":2,"Operator1Value":1.3,"Operator2Mode":0,"Operator2Value":5},"DecimalsMode":3} --shopid <店铺ID>

# 示例：统一价99.9元
wdjlcli config set PriceHandle {"PriceMode":1,"FixedPrice":99.9} --shopid <店铺ID>
```

---

#### `PriceDiscount` — 折扣设置

```
wdjlcli config set PriceDiscount 9.5 --shopid <店铺ID>
# 默认9.9（即9.9折）
```

---

#### `SkuPriceMultiple` — SKU价格倍差过大处理

```
wdjlcli config set SkuPriceMultiple 1 --shopid <店铺ID>
# 0=不处理（默认），1=对最低价加价，2=对最高价减价，3=删除超高价SKU，4=删除超低价SKU
```

---

### F. SKU配置

#### `SkuStock` — SKU库存处理

| 字段 | 类型 | 说明 |
|------|------|------|
| `StockProcessType` | int | 0=不处理（默认），1=统一库存，2=加库存 |
| `UnifiedStockValue` | int? | 统一库存数值（StockProcessType=1） |
| `AddStockValue` | int? | 加库存数值（StockProcessType=2） |
| `IgnoreZeroStock` | bool | 不修改库存为0的SKU（默认 true） |

```
# 示例：全部SKU统一库存999
wdjlcli config set SkuStock {"StockProcessType":1,"UnifiedStockValue":999,"IgnoreZeroStock":true} --shopid <店铺ID>
```

---

#### `SkuLowStock` — SKU低库存处理

| 字段 | 类型 | 说明 |
|------|------|------|
| `ProcessType` | int | 0=不处理（默认），1=修改库存为目标值，2=删除该SKU |
| `ThresholdValue` | int? | 触发阈值（库存小于此值时处理） |
| `TargetStockValue` | int? | 目标库存数值（ProcessType=1） |

```
# 示例：库存<5时改为100
wdjlcli config set SkuLowStock {"ProcessType":1,"ThresholdValue":5,"TargetStockValue":100} --shopid <店铺ID>
```

---

#### `SkuCode` — SKU商家编码

| 字段 | 类型 | 说明 |
|------|------|------|
| `CodeType` | int | 0=不设置，1=上家商家编码（默认），2=自定义 |
| `BuildType` | int | 0=商品ID+规格1+规格2（默认），1=商品ID+规格拼接，2=商家编码+规格，3=商家编码+规格拼接，4=仅规格 |
| `SplitCharType` | int | 0=/，1=_（默认），2=-，3=\|，4=空格，5=#，6=无 |
| `ChineseHandleType` | int | 0=不处理，1=转首字母（默认），2=删除中文 |

```
wdjlcli config set SkuCode {"CodeType":2,"BuildType":0,"SplitCharType":1,"ChineseHandleType":1} --shopid <店铺ID>
```

---

#### `SkuValueReplaceMap` — SKU规格值替换

Key=源规格值，Value=替换值。

```
wdjlcli config set SkuValueReplaceMap {"均码":"ONE SIZE","藏青":"深蓝"} --shopid <店铺ID>
```

---

#### `SkuSpecMap` — SKU规格名转换

Key=上游规格名，Value=下游规格名。

```
wdjlcli config set SkuSpecMap {"颜色分类":"颜色","尺码":"尺寸"} --shopid <店铺ID>
```

---

#### `SkuMergeRules` — SKU规格合并

格式：`规格1+规格2=合并后规格名`，多条用逗号分隔。

```
wdjlcli config set SkuMergeRules 颜色+尺码=款式 --shopid <店铺ID>
```

---

#### `SkuPrefixSuffix` — SKU值前后缀

| 字段 | 类型 | 说明 |
|------|------|------|
| `AddPrefixs` | string[]? | 前缀列表（随机选一） |
| `AddSuffixs` | string[]? | 后缀列表（随机选一） |
| `ScopeType` | int | 0=全部规格（默认），1=指定规格 |
| `TargetSpecNames` | string? | 指定规格名，逗号分隔（ScopeType=1） |

```
wdjlcli config set SkuPrefixSuffix {"AddSuffixs":["新款"],"ScopeType":1,"TargetSpecNames":"颜色"} --shopid <店铺ID>
```

---

#### `SkuSpecValueDelKeyword` — SKU规格值清除关键词

多个关键词逗号分隔。

```
wdjlcli config set SkuSpecValueDelKeyword 预售,定制 --shopid <店铺ID>
```

---

#### `SkuPadding` — SKU缺失自动补齐

| 字段 | 类型 | 说明 |
|------|------|------|
| `IsAutoPadding` | bool | 是否开启（默认 false） |
| `SkuPaddingMap` | dict? | Key=规格名，Value=预设规格值（逗号分隔） |

```
wdjlcli config set SkuPadding {"IsAutoPadding":true,"SkuPaddingMap":{"颜色":"红色,蓝色,黄色","尺码":"S,M,L,XL"}} --shopid <店铺ID>
```

---

#### `DiySku` — 自定义SKU

添加额外规格项（规格名须在上游存在，重复项不处理）。

| 字段 | 类型 | 说明 |
|------|------|------|
| `SpecName` | string | 规格名称（如"颜色"）— 必填 |
| `SpecValues` | string | 规格选项，逗号分隔（如"红色,蓝色"）— 必填 |
| `PriceMode` | int | 0=随机价格，1=SKU最高价（默认），2=SKU最低价 |
| `RandomPriceMin` | decimal? | 随机价最小值（PriceMode=0） |
| `RandomPriceMax` | decimal? | 随机价最大值（PriceMode=0） |
| `Stock` | int | 统一库存 — 必填 |
| `ImageMode` | int | 0=第一张主图（默认），1=自定义图片，2=其他SKU图，3=不添加 |
| `CustomImageUrl` | string? | 自定义图片URL（ImageMode=1） |

```
wdjlcli config set DiySku {"Items":[{"SpecName":"颜色","SpecValues":"红色,蓝色","PriceMode":1,"Stock":100,"ImageMode":0}]} --shopid <店铺ID>
```

---

### G. 主图与视频配置

#### `MainImgDel` — 主图删除

| 字段 | 类型 | 说明 |
|------|------|------|
| `DeleteMode` | int | 0=不删除（默认），1=仅保留X张，2=删除第X张，3=删除前X张+后Y张 |
| `KeepCount` | int? | 保留张数（DeleteMode=1） |
| `DeleteSpecificIndex` | int? | 删除第几张（DeleteMode=2，从1计数） |
| `DeleteHeadCount` | int? | 删除前几张（DeleteMode=3） |
| `DeleteTailCount` | int? | 删除后几张（DeleteMode=3） |

```
# 示例：仅保留前5张主图
wdjlcli config set MainImgDel {"DeleteMode":1,"KeepCount":5} --shopid <店铺ID>
```

---

#### `MainImgOrder` — 主图顺序

| 字段 | 类型 | 说明 |
|------|------|------|
| `MainImgOrderMode` | int | 0=不修改（默认），1=随机打乱，2=自定义顺序 |
| `CustomOrderList` | int[]? | 自定义顺序索引列表（如[3,1,2]，拼多多支持6-10张） |

```
wdjlcli config set MainImgOrder {"MainImgOrderMode":1} --shopid <店铺ID>
```

---

#### `MainImgReplace` — 主图替换

| 字段 | 类型 | 说明 |
|------|------|------|
| `ReplaceMode` | int | 0=不替换（默认），1=用SKU图替换，2=指定位置替换自定义图 |
| `CustomReplaceImages` | dict? | Key=主图索引(1-10)，Value=图片URL |

```
# 示例：将第1张主图替换为自定义图片
wdjlcli config set MainImgReplace {"ReplaceMode":2,"CustomReplaceImages":{"1":"https://example.com/img1.jpg"}} --shopid <店铺ID>
```

---

#### `MainImgPaddingMode` — 补齐主图

```
wdjlcli config set MainImgPaddingMode 1 --shopid <店铺ID>
# 0=不补齐（默认），1=复制主图补齐，2=复制SKU图补齐
```

---

#### `MainImgSize` — 主图1:1尺寸处理

| 字段 | 类型 | 说明 |
|------|------|------|
| `SizeOption` | int | 0=800x800（默认），1=1440x1440 |
| `ProcessMode` | int | 0=填充（默认），1=裁剪，2=拉伸 |

---

#### `MainImg34Size` — 主图3:4尺寸处理

| 字段 | 类型 | 说明 |
|------|------|------|
| `SourceMode` | int | 0=不上传，1=使用上家（默认），2=从1:1生成 |
| `SizeOption` | int | 0=1440x1920（默认），1=750x1000 |
| `ProcessMode` | int | 0=填充（默认），1=裁剪，2=拉伸 |

---

#### `MainImgFlipMode` — 主图翻转

| 字段 | 类型 | 说明 |
|------|------|------|
| `FlipMode` | int | 0=不翻转（默认），1=全部翻转，2=指定主图翻转 |
| `FlipIndices` | int[]? | 指定翻转的主图索引(1-10)，FlipMode=2时有效 |

```
# 示例：翻转第1、3张主图
wdjlcli config set MainImgFlipMode {"FlipMode":2,"FlipIndices":[1,3]} --shopid <店铺ID>
```

---

#### `MainVideoCopy` — 主图视频

| 字段 | 类型 | 说明 |
|------|------|------|
| `VideoMode` | int | 0=使用上家视频（默认），1=不上传，2=自定义视频 |
| `CustomVideoUrl` | string? | 视频URL（VideoMode=2，时长10s~10min，宽高比9:16，≤300MB） |

---

### H. 详情图配置

#### `DetailImgDel` — 删除详情图

| 字段 | 类型 | 说明 |
|------|------|------|
| `DeleteIndex` | int? | 删除第X张（从1计数） |
| `DeleteHeadCount` | int? | 删除前X张 |
| `DeleteTailCount` | int? | 删除后X张 |
| `KeepCount` | int? | 仅保留X张 |

```
# 示例：删除前1张和后2张
wdjlcli config set DetailImgDel {"DeleteHeadCount":1,"DeleteTailCount":2} --shopid <店铺ID>
```

---

#### `DetailImgLinkImgMode` — 有链接详情图处理

```
wdjlcli config set DetailImgLinkImgMode 1 --shopid <店铺ID>
# 0=不处理（默认），1=删除有链接的详情图，2=保留但去除链接
```

---

#### `DetailCustomHeads` / `DetailCustomTails` — 自定义详情首尾图

```
wdjlcli config set DetailCustomHeads ["https://example.com/head.jpg"] --shopid <店铺ID>
wdjlcli config set DetailCustomTails ["https://example.com/tail.jpg"] --shopid <店铺ID>
```

---

#### `IgnoreSourceDetailImgs` — 不使用上家详情图

```
wdjlcli config set IgnoreSourceDetailImgs true --shopid <店铺ID>
```

---

#### `DetailImgInsert` — 插入详情图

| 字段 | 类型 | 说明 |
|------|------|------|
| `InsertMode` | int | 0=不插入（默认），1=全部SKU图，2=全部主图，3=指定主图 |
| `InsertMainIndices` | int[]? | 指定插入的主图索引(1-10)，InsertMode=3时有效 |
| `InsertPositionMode` | int? | 0=从第一张插入（默认），1=从最后插入，2=随机 |

---

#### `DetailImgHeight` — 详情图高度切片

| 字段 | 类型 | 说明 |
|------|------|------|
| `SplitMode` | int | 0=平台限制（默认），1=自定义高度 |
| `CustomeSplitHeight` | int? | 自定义切片高度px（SplitMode=1） |

---

#### `DetailImgWidthMode` — 详情图宽度

```
wdjlcli config set DetailImgWidthMode 1 --shopid <店铺ID>
# 0=不处理（默认），1=设为750px，2=设为790px
```

---

#### 其他详情图开关

```
wdjlcli config set DetailImgFilterSmallImgs true --shopid <店铺ID>  # 过滤小图
wdjlcli config set DetailImgShuffle true --shopid <店铺ID>          # 随机打乱详情图顺序
wdjlcli config set DetailImgFlip true --shopid <店铺ID>             # 翻转详情图
wdjlcli config set DetailImgAutoMerge true --shopid <店铺ID>        # 超限时自动合并
wdjlcli config set NoUploadTaobaoMobile true --shopid <店铺ID>      # 不上传淘宝手机端详情
wdjlcli config set NoUploadTaobaoPC true --shopid <店铺ID>          # 不上传淘宝PC端详情
```

---

### I. 素材图配置

#### `WhiteImgBuild` — 白底图

```
# 0=不上传，1=使用货源白底图（默认），2=从主图第X张生成
wdjlcli config set WhiteImgBuild {"WhiteBgMode":1} --shopid <店铺ID>
wdjlcli config set WhiteImgBuild {"WhiteBgMode":2,"WhiteBgFromIndex":1} --shopid <店铺ID>
```

---

#### `RectangleImgBuild` — 长图/导购图

```
# 0=不上传，1=使用货源长图（默认），2=从主图第X张生成
wdjlcli config set RectangleImgBuild {"RectangleImgMode":1} --shopid <店铺ID>
```

---

### J. SKU图片配置

#### `SkuImgMiss` — SKU图片缺失处理

| 字段 | 类型 | 说明 |
|------|------|------|
| `MissingHandleMode` | int | 0=用其他SKU图补充（默认），1=用指定主图，2=自定义图片，3=过滤无图SKU |
| `MainImageIndex` | int? | 主图索引(1-10)，MissingHandleMode=1时有效 |
| `CustomImageUrl` | string? | 自定义图片URL，MissingHandleMode=2时有效 |

```
# 示例：缺图时用第1张主图替代
wdjlcli config set SkuImgMiss {"MissingHandleMode":1,"MainImageIndex":1} --shopid <店铺ID>
```

---

#### `SkuImgSize` — SKU图片尺寸

| 字段 | 类型 | 说明 |
|------|------|------|
| `EnableResize` | bool | 是否启用尺寸处理（默认 true） |
| `SizeOption` | int | 0=800x800（默认） |
| `ProcessMode` | int | 0=填充（默认），1=裁剪，2=拉伸 |

---

#### `SkuEnableFlip` — SKU图翻转

```
wdjlcli config set SkuEnableFlip true --shopid <店铺ID>
```

---

### K. 水印配置

#### `Watermark` — 图片水印

| 字段 | 类型 | 说明 |
|------|------|------|
| `SkuImgWaterOption` | bool | SKU图加水印 |
| `DescImgWaterOption` | bool | 详情图加水印 |
| `MainImgWater` | int? | null/0=不加，1=全部主图，2=首图，3=指定主图 |
| `MainImgWaterIndexList` | int[]? | 指定水印主图索引（MainImgWater=3时有效） |
| `WaterType` | string | `text`=文字水印，`image`=图片水印，`border`=边框水印 |
| `WaterItemConfig` | 对象 | 水印详细参数 |

**WaterItemConfig 字段**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `Position` | string | `lefttop`/`leftbottom`/`righttop`/`rightbottom`（默认）/`center`/`topcenter`/`bottomcenter`/`full`/`random` |
| `Text` | string? | 文字内容（WaterType=text） |
| `FontName` | string | 字体：`黑体`/`楷体`/`等线`等 |
| `FontSize` | float? | 字体大小（默认12） |
| `FontColorRgba` | string? | 颜色，格式`R,G,B,A`，如`255,255,255,180` |
| `IsBold` | bool | 是否加粗 |
| `IsTilt` | bool | 是否倾斜 |
| `ImageOpacity` | float | 图片透明度（0.1~1，默认1） |
| `ImageUrl` | string? | 图片水印URL（WaterType=image） |
| `BorderWaterUrl` | string? | 边框水印URL（WaterType=border） |

```
# 示例：首图右下角加文字水印
wdjlcli config set Watermark {"MainImgWater":2,"WaterType":"text","WaterItemConfig":{"Position":"rightbottom","Text":"我的店铺","FontName":"黑体","FontSize":20,"FontColorRgba":"255,255,255,180","IsBold":true}} --shopid <店铺ID>
```

---

### L. 平台与店铺配置

#### `GeneralService` — 通用售后设置

| 字段 | 类型 | 说明 |
|------|------|------|
| `DamageReturn` | bool | 破损包退 |
| `WarrantyService` | bool | 保修服务 |
| `SevenDayReturn` | bool | 7天无理由退货 |
| `SevenDayReturnOption` | int? | 1=支持（默认），2=包装未破损，3=安装后不支持，4=激活后不支持，5=使用后不支持，6=定制不支持，7=合约不支持 |

```
wdjlcli config set GeneralService {"SevenDayReturn":true,"SevenDayReturnOption":1,"DamageReturn":true} --shopid <店铺ID>
```

---

#### `TaobaoService` — 淘宝售后配置

| 字段 | 类型 | 说明 |
|------|------|------|
| `AppraisalCommitment` | bool | 鉴定承诺 |
| `AfterSalesService` | bool | 售后服务 |
| `AfterSalesServiceOption` | int? | 0=全国联保，1=店铺保修，2=店铺三包（默认），3=其他 |

---

#### `PinduoduoService` — 拼多多售后配置

| 字段 | 类型 | 说明 |
|------|------|------|
| `FakeCompensateTen` | bool | 假一赔十 |
| `ShortageReturn` | bool | 缺重包退 |
| `NationalWarranty` | bool | 全国联保 |
| `ReplaceOnly` | bool | 只换不修 |
| `SecretDelivery` | bool | 保密发货 |
| `BrandNew` | bool | 全新商品（默认 true） |

---

#### `DouyinService` — 抖音售后配置

| 字段 | 类型 | 说明 |
|------|------|------|
| `AllergyReturn` | bool | 过敏包退 |
| `CustomerPhone` | string? | 客服电话 |

---

#### `TaobaoSkuDisplayMode` — 淘宝规格展示模式

```
wdjlcli config set TaobaoSkuDisplayMode 1 --shopid <店铺ID>
# 0=单层展示（自定义填写），1=分层展示（匹配标准属性，默认）
```

---

#### `DouyinLimit` — 抖音限购配置

| 字段 | 类型 | 说明 |
|------|------|------|
| `LimitEnabled` | bool | 是否开启限购 |
| `MaxCountByUser` | int? | 每用户累计限购数（件） |
| `MaxCountByOrder` | int? | 每单最多购买数（件） |
| `MinCountByOrder` | int? | 每单最少购买数（件） |

```
wdjlcli config set DouyinLimit {"LimitEnabled":true,"MaxCountByUser":2,"MaxCountByOrder":1} --shopid <店铺ID>
```

---

#### `ShopDeliveryConfs` — 店铺发货与运费配置

> 建议通过 `wdjlcli config set shop.freight --shopid <店铺ID>` 交互式选择运费模板，而非手动构造 JSON。

| 字段 | 类型 | 说明 |
|------|------|------|
| `ShopID` | string | 店铺ID |
| `ShopName` | string | 店铺名称 |
| `PlatformEnum` | string | 平台标识（Taobao/Pdd/Douyin/Jd 等） |
| `DeliveryMode` | int | 0=现货发货（默认），1=全款预售 |
| `SpotDeliveryHour` | int? | 发货时间：1=当日，2=次日，48=48h（默认），72=3天，120=5天，168=7天 |
| `ShippingTemplateId` | string? | 运费模板ID |
| `ShippingTemplateName` | string? | 运费模板名称 |
| `ShippingTemplateMode` | int | 0=店铺默认运费模板（默认），1=自定义运费模板 |
| `SizeChartTemplate` | string? | 尺码模板名称 |
