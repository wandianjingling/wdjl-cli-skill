> 本文档是 [SKILL.md](./SKILL.md) 的配套参考文档，包含商品批量修改 `goodsupdate submit` 命令 `--options` 参数的详细说明。
> 仅在组装 `goodsupdate submit` 的修改参数时需要读取本文档。

## 批量修改参数参考

批量修改通过 `goodsupdate submit` 提交，`-t|--type` 指定修改类型（枚举名不区分大小写，或数值），`-o|--options` 传入该类型对应的参数 JSON。字段名使用 PascalCase，未传字段按后端默认值或空值处理。

```
wdjlcli goodsupdate submit -s <店铺ID> -t <类型> -o '<JSON>'
wdjlcli goodsupdate submit -s <店铺ID> -t <类型> --options-file options.json
```

> **PowerShell 注意**：Windows PowerShell 中传 JSON 需用单引号包裹或转义双引号，长 JSON 易出引号/编码问题，建议优先使用 `--options-file` 从 JSON 文件读取参数。

**修改类型总览**（`-t|--type` 取值）：

| 枚举名 | 数值 | 说明 | Options 类型 |
|--------|------|------|--------------|
| `title` | 1 | 改标题 | `UpdateTitleOptions` |
| `price` | 2 | 改价格 | `UpdatePriceOptions` |
| `skucode` | 3 | 改SKU编码（商家编码） | `UpdateSkuCodeOptions` |
| `mainimage` | 4 | 改主图 | `UpdateMainImageOptions` |
| `brand` | 5 | 改品牌 | `UpdateBrandOptions` |
| `category` | 6 | 改类目 | `UpdateCategoryOptions` |
| `property` | 7 | 改属性 | `UpdatePropertyOptions` |
| `shippingmode` | 8 | 改发货模式 | `UpdateShippingModeOptions` |
| `qualification` | 9 | 改资质 | `UpdateQualificationOptions` |
| `deletegoods` | 10 | 删除商品 | `DeleteGoodsOptions` |
| `salestatus` | 11 | 上下架 | `UpdateSaleStatusOptions` |
| `slowsaleclean` | 12 | 清理滞销 | `SlowSaleCleanOptions` |
| `stock` | 13 | 改库存 | `UpdateStockOptions` |
| `skuname` | 14 | 改SKU名称 | `UpdateSkuNameOptions` |
| `deletesku` | 15 | 删除SKU | `DeleteSkuOptions` |
| `shufflesku` | 16 | 打乱SKU | `ShuffleSkuOptions` |
| `replacesku` | 17 | 替换SKU | `ReplaceSkuOptions` |
| `addsku` | 18 | 新增SKU | `UpdateAddSkuOptions` |
| `mainimage34` | 19 | 改3:4主图 | `UpdateMainImage34Options` |
| `detailimage` | 20 | 改详情图 | `UpdateDetailImageOptions` |
| `mainvideo` | 21 | 改主视频 | `UpdateMainVideoOptions` |
| `guideimage` | 22 | 改导购图 | `UpdateGuideImageOptions` |
| `whiteimage` | 23 | 改白底图 | `UpdateWhiteImageOptions` |
| `watermark` | 24 | 改水印 | `UpdateWatermarkOptions` |
| `sizetemplate` | 25 | 改尺码表 | `UpdateSizeTemplateOptions` |
| `freighttemplate` | 26 | 改运费模板 | `UpdateFreightTemplateOptions` |
| `sevendayreturn` | 27 | 七天无理由 | `UpdateSevenDayReturnOptions` |
| `purchaselimit` | 28 | 改限购 | `UpdatePurchaseLimitOptions` |

> **平台支持度**：各平台支持类型不一（闲鱼仅支持改标题；得物不支持发货模式/资质/运费模板等），提交不支持的类型会整批失败并写明原因。

---

#### `title`（type=1）— 修改商品标题

| 字段 | 类型 | 说明 |
|------|------|------|
| `CleanKeywords` | string | 需要清除的关键词，多个用逗号分隔 |
| `ReplaceRules` | string | 替换规则文本，格式如 `2025=2026`，一行一个或逗号分隔 |
| `TitlePrefix` | string | 标题前缀，仅 1 个 |
| `TitleSuffix` | string | 标题后缀，仅 1 个 |
| `OverflowMode` | int | 标题超长处理方式，`0` 跳过超长商品（默认），`1` 截掉尾部超长内容 |

```
# 清除"旗舰店"关键词，把 2025 替换为 2026，并加前缀
wdjlcli goodsupdate submit -s <店铺ID> -t title -o '{"CleanKeywords":"旗舰店","ReplaceRules":"2025=2026","TitlePrefix":"【新品】","OverflowMode":1}'
```

---

#### `price`（type=2）— 修改商品价格

继承 `PriceHandleConf`，支持统一价、按货源价加价、阶梯加价三种模式。

| 字段 | 类型 | 说明 |
|------|------|------|
| `PriceMode` | int | 价格处理方式，`0` 不处理（默认），`1` 统一价，`2` 按货源价加价，`3` 阶梯加价 |
| `FixedPrice` | decimal | 统一价金额（`PriceMode=1` 时必填） |
| `PriceItem` | object | 按货源价加价参数（`PriceMode=2` 时必填），类型为 [PriceItem](#priceitem) |
| `SkuMiniPriceItem` | object | SKU 最低价加价参数，类型为 [PriceItem](#priceitem)；启用后最低价 SKU 使用该参数，其他 SKU 仍用 `PriceItem` |
| `PriceTierItems` | object[] | 阶梯加价参数集合（`PriceMode=3` 时使用），元素为 `{ "ThresholdPrice": 门槛金额, "PriceItem": {...} }`；货源价 ≥ 门槛时命中，满足多个条件时只使用门槛最高的一项 |
| `DecimalsMode` | int | 小数处理方式，`1` 抹零，`2` 四舍五入保留 1 位小数，`3` 四舍五入保留 2 位小数（默认），`4` 固定尾数金额 |
| `FixedDecimalsValue` | decimal | 固定尾数金额（`DecimalsMode=4` 时必填） |

```
# 全店统一价 99.9 元
wdjlcli goodsupdate submit -s <店铺ID> -t price -o '{"PriceMode":1,"FixedPrice":99.9}'

# 按货源价加价：先加 5 元，再加 10%
wdjlcli goodsupdate submit -s <店铺ID> -t price -o '{"PriceMode":2,"PriceItem":{"Operator1Mode":0,"Operator1Value":5,"Operator2Mode":1,"Operator2Value":10}}'

# 阶梯加价：货源价满 100 元加 20%，否则加 10%
wdjlcli goodsupdate submit -s <店铺ID> -t price -o '{"PriceMode":3,"PriceTierItems":[{"ThresholdPrice":100,"PriceItem":{"Operator1Mode":1,"Operator1Value":20}},{"ThresholdPrice":0,"PriceItem":{"Operator1Mode":1,"Operator1Value":10}}]}'
```

<a id="priceitem"></a>

###### PriceItem（价格公式项）

后端先执行 `Operator1`，再执行 `Operator2`。

| 字段 | 类型 | 说明 |
|------|------|------|
| `Operator1Mode` | int | 第 1 次价格操作方式，`0` 加金额，`1` 加百分比（支持负数表示减百分比），`2` 乘，`3` 除，`4` 减金额；未传或无效时跳过 |
| `Operator1Value` | decimal | 第 1 次价格操作数值（`Operator1Mode` 有效时必填），金额单位为元，百分比模式下按百分比值处理 |
| `Operator2Mode` | int | 第 2 次价格操作方式，取值同 `Operator1Mode`；未传或无效时跳过 |
| `Operator2Value` | decimal | 第 2 次价格操作数值（`Operator2Mode` 有效时必填） |
| `MinPrice` | decimal | 最低价格保护值 |

---

#### `skucode`（type=3）— 修改SKU编码（商家编码）

继承 `SkuCodeConf`。

| 字段 | 类型 | 说明 |
|------|------|------|
| `SkuFilter` | object | SKU 筛选条件，类型为 [GoodsUpdateSkuFilterOptions](#skufilter) |
| `CodeType` | int | SKU 商家编码模式，`1` 公式生成（默认），`2` 自定义 |
| `IsFirstUseSourceCode` | bool | 自定义编码时是否优先使用上家商品商家编码（`CodeType=2` 时有效，默认 `true`） |
| `BuildType` | int | 编码生成方式（`CodeType=2` 时有效），`0` 商品ID+规格1+规格2+规格3，`1` 商品ID+规格值拼接，`2` 商家编码+规格1+规格2+规格3，`3` 商家编码+规格值拼接，`4` 规格1+规格2+规格3 |
| `SplitCharType` | int | 分隔符类型，`0` `/`，`1` `_`（默认），`2` `-`，`3` `\|`，`4` 空格，`5` `#`，`6` 无分隔符 |
| `ChineseHandleType` | int | 中文处理模式，`0` 不处理，`1` 转为首字母（默认），`2` 删除中文 |
| `SkuCodeMath` | object | 公式编码生成配置（`CodeType=1` 时有效），字段为 `BuildType`/`SplitCharType`/`ChineseHandleType`，含义同上 |
| `SkuCodeCustomModify` | object | 自定义编码修改配置（`CodeType=2` 时有效），字段见下表 |

`SkuCodeCustomModify` 字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `ClearKeywordsText` | string | 需要清除的 SKU 关键字，多个用逗号分隔 |
| `ReplaceKeywordsText` | string | 替换关键字文本，格式如 `2025=2026`，一行一个或逗号分隔 |
| `TitlePrefix` | string | 编码前缀 |
| `TitleSuffix` | string | 编码后缀 |
| `ApplyToSkuSpecName` | bool | 是否同时应用于指定 SKU 规格名 |
| `SpecType` | int | 规格类型，`0` 其他（默认），`1` 颜色，`2` 尺码 |
| `SpecNamesText` | string | 指定修改的 SKU 规格名文本，如 `颜色,尺码` |
| `OverLengthHandleMode` | int | 超出字数处理方式，`1` 放弃修改（默认），`2` 删除尾部超出部分 |

```
# 公式生成编码：下划线分隔，中文转首字母
wdjlcli goodsupdate submit -s <店铺ID> -t skucode -o '{"CodeType":1,"SkuCodeMath":{"BuildType":0,"SplitCharType":1,"ChineseHandleType":1}}'
```

---

#### `mainimage`（type=4）— 修改商品主图

| 字段 | 类型 | 说明 |
|------|------|------|
| `MainImgOrder` | object | 主图顺序配置，见 [MainImgOrderConf](#mainimgorder) |
| `MainImgReplace` | object | 主图替换配置，见 [MainImgReplaceConf](#mainimgreplace) |
| `MainImgDel` | object | 主图删除配置，见 [MainImgDelConf](#mainimgdel) |
| `MainImgFlipMode` | object | 主图翻转配置，见 [MainImgFlipModeConf](#mainimgflip) |

```
# 仅保留前 5 张主图并随机打乱顺序
wdjlcli goodsupdate submit -s <店铺ID> -t mainimage -o '{"MainImgDel":{"DeleteMode":1,"KeepCount":5},"MainImgOrder":{"MainImgOrderMode":1}}'
```

---

#### `brand`（type=5）— 修改品牌

| 字段 | 类型 | 说明 |
|------|------|------|
| `BrandMode` | int | 品牌设置，`1` 无品牌，`2` 不设置，`3` 自定义 |
| `BrandWord` | string | 自定义品牌（`BrandMode=3` 时必填） |

```
# 全部设置为无品牌
wdjlcli goodsupdate submit -s <店铺ID> -t brand -o '{"BrandMode":1}'

# 自定义品牌
wdjlcli goodsupdate submit -s <店铺ID> -t brand -o '{"BrandMode":3,"BrandWord":"我的品牌"}'
```

---

#### `category`（type=6）— 修改类目

| 字段 | 类型 | 说明 |
|------|------|------|
| `CustomCategories` | object[] | 手动选择的类目列表（必填），元素为 `{ "PlatformEnum": 平台枚举值, "Cids": [类目ID逐级], "CNames": [类目名称逐级] }`；`PlatformEnum` 常用值：`1` 淘宝，`2` 天猫，`3` 拼多多，`4` 抖店，`5` 京东，`6` 快手，`7` 微信小店/视频号，`8` 阿里，`9` 小红书 |

```
wdjlcli goodsupdate submit -s <店铺ID> -t category -o '{"CustomCategories":[{"PlatformEnum":3,"Cids":["123","456"],"CNames":["女装","连衣裙"]}]}'
```

---

#### `property`（type=7）— 修改商品属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `Properties` | object[] | 需要设置的属性列表（必填），元素为 `{ "Name": 属性名, "Value": 属性值 }` |

```
wdjlcli goodsupdate submit -s <店铺ID> -t property -o '{"Properties":[{"Name":"材质","Value":"纯棉"},{"Name":"风格","Value":"简约"}]}'
```

---

#### `shippingmode`（type=8）— 修改发货模式

继承 `ShopDeliveryConf`。得物等平台不支持。

| 字段 | 类型 | 说明 |
|------|------|------|
| `ShippingTemplateId` | string | 运费模板 ID |
| `ShippingTemplateName` | string | 运费模板名称 |
| `ShippingTemplateMode` | int | 运费模板类型，`0` 店铺默认模板，`1` 自定义模板 |
| `PlatExten` | object/string | 平台扩展配置，可传 JSON 对象或 JSON 字符串；后端按平台反序列化为对应平台扩展类型 |

```
wdjlcli goodsupdate submit -s <店铺ID> -t shippingmode -o '{"ShippingTemplateMode":1,"ShippingTemplateId":"12345","ShippingTemplateName":"全国包邮"}'
```

---

#### `qualification`（type=9）— 修改资质信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `Items` | object[] | 资质图片列表，元素为 `{ "Name": 资质名称(必填), "ImageUrls": [图片URL], "UseFirstMainImg": 是否用商品第一张主图 }` |

```
wdjlcli goodsupdate submit -s <店铺ID> -t qualification -o '{"Items":[{"Name":"食品生产许可证","UseFirstMainImg":true}]}'
```

---

#### `deletegoods`（type=10）— 删除商品

无 options 参数，未传或传 `{}` 均可。

```
# 删除指定商品
wdjlcli goodsupdate submit -s <店铺ID> -t deletegoods -g 123456789,987654321

# 删除全店商品（危险操作，请与用户确认）
wdjlcli goodsupdate submit -s <店铺ID> -t deletegoods -o '{}'
```

---

#### `salestatus`（type=11）— 修改上下架状态

继承 `GoodStateConf`。

| 字段 | 类型 | 说明 |
|------|------|------|
| `GoodState` | int | 上下架状态，`0` 立即上架，`1` 放入仓库（下架），`2` 放入草稿箱，`3` 定时上架 |
| `ToSaleTime` | string | 定时上架时间（`GoodState=3` 时必填） |

```
# 指定商品下架（放入仓库）
wdjlcli goodsupdate submit -s <店铺ID> -t salestatus -g 123456789 -o '{"GoodState":1}'

# 全店商品定时上架
wdjlcli goodsupdate submit -s <店铺ID> -t salestatus -o '{"GoodState":3,"ToSaleTime":"2026-10-08 10:00:00"}'
```

---

#### `slowsaleclean`（type=12）— 清理滞销商品

| 字段 | 类型 | 说明 |
|------|------|------|
| `Action` | int | 命中后的处理动作，`0` 不处理，`1` 删除商品，`2` 下架 |

```
wdjlcli goodsupdate submit -s <店铺ID> -t slowsaleclean -o '{"Action":2}'
```

---

#### `stock`（type=13）— 修改库存

| 字段 | 类型 | 说明 |
|------|------|------|
| `SkuFilter` | object | SKU 筛选条件，类型为 [GoodsUpdateSkuFilterOptions](#skufilter) |
| `SkuStock` | object | SKU 库存配置，见下表 |
| `SkuLowStock` | object | 低库存处理配置，见下表 |

`SkuStock` 字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `StockProcessType` | int | SKU 库存处理模式，`1` 统一库存，`2` 加库存，`3` 减库存 |
| `UnifiedStockValue` | int | 统一库存数值（`StockProcessType=1` 时必填） |
| `AddStockValue` | int | 加库存数值（`StockProcessType=2` 时必填），在原库存上增加 |
| `ReduceStockValue` | int | 减库存数值（`StockProcessType=3` 时必填），在原库存上减少 |
| `IgnoreZeroStock` | bool | 是否不修改库存为 `0` 的 SKU，默认 `true` |

`SkuLowStock` 字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `ProcessType` | int | 低库存处理模式，`0` 不处理（默认），`1` 修改库存，`2` 下架 SKU |
| `ThresholdValue` | int | 触发处理的库存阈值（`ProcessType=1/2` 时必填），库存小于该值时命中 |
| `TargetStockValue` | int | 命中低库存后设置成的目标库存（`ProcessType=1` 时必填） |

```
# 全店统一库存为 999
wdjlcli goodsupdate submit -s <店铺ID> -t stock -o '{"SkuStock":{"StockProcessType":1,"UnifiedStockValue":999}}'

# 名称含"红色"的 SKU 加 100 库存
wdjlcli goodsupdate submit -s <店铺ID> -t stock -o '{"SkuFilter":{"SkuKeyword":"红色"},"SkuStock":{"StockProcessType":2,"AddStockValue":100}}'

# 库存小于 5 时自动设为 50
wdjlcli goodsupdate submit -s <店铺ID> -t stock -o '{"SkuLowStock":{"ProcessType":1,"ThresholdValue":5,"TargetStockValue":50}}'
```

---

#### `skuname`（type=14）— 修改SKU名称

| 字段 | 类型 | 说明 |
|------|------|------|
| `SkuFilter` | object | SKU 筛选条件，类型为 [GoodsUpdateSkuFilterOptions](#skufilter) |
| `SkuSpecValueDelKeyword` | string | 需要清除的 SKU 关键字，多个用逗号分隔 |
| `ReplaceKeywordsText` | string | SKU 值替换规则，格式如 `2025=2026` |
| `AddPrefixs` | string | SKU 值前缀，仅 1 项 |
| `AddSuffixs` | string | SKU 值后缀，仅 1 项 |
| `OverLengthHandleMode` | int | 超出字数处理方式，`1` 放弃修改（默认），`2` 删除尾部超出部分 |

```
# 给 SKU 名称加后缀
wdjlcli goodsupdate submit -s <店铺ID> -t skuname -o '{"AddSuffixs":"-热销款"}'

# 替换 SKU 名称中的关键字
wdjlcli goodsupdate submit -s <店铺ID> -t skuname -o '{"ReplaceKeywordsText":"2025=2026","OverLengthHandleMode":2}'
```

---

#### `deletesku`（type=15）— 删除SKU

| 字段 | 类型 | 说明 |
|------|------|------|
| `SkuFilter` | object | SKU 筛选条件，类型为 [GoodsUpdateSkuFilterOptions](#skufilter) |
| `EnablePriceBelow` | bool | 是否启用价格条件 |
| `PriceBelow` | decimal | 删除低于该价格的 SKU（`EnablePriceBelow=true` 时必填） |
| `EnableStockBelow` | bool | 是否启用库存条件 |
| `StockBelow` | int | 删除低于该库存的 SKU（`EnableStockBelow=true` 时必填） |

```
# 删除名称含"预售"的 SKU
wdjlcli goodsupdate submit -s <店铺ID> -t deletesku -o '{"SkuFilter":{"SkuKeyword":"预售"}}'

# 删除价格低于 1 元或库存低于 1 的 SKU
wdjlcli goodsupdate submit -s <店铺ID> -t deletesku -o '{"EnablePriceBelow":true,"PriceBelow":1,"EnableStockBelow":true,"StockBelow":1}'
```

---

#### `shufflesku`（type=16）— 打乱SKU

无 options 参数，未传或传 `{}` 均可。

```
wdjlcli goodsupdate submit -s <店铺ID> -t shufflesku -g 123456789 -o '{}'
```

---

#### `replacesku`（type=17）— 替换SKU

| 字段 | 类型 | 说明 |
|------|------|------|
| `SourceLink` | string | 需要解析的商品链接 |
| `Items` | object[] | 替换 SKU 列表（必填），元素字段见下表 |
| `OverLengthHandleMode` | int | 超出字数处理方式，`1` 放弃修改（默认），`2` 删除尾部超出部分 |

`Items` 元素字段（`SpecName`/`SpecValue`/`SkuName` 已废弃，请使用 `SpecNames`/`SpecValues`）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `SpecNames` | string[] | 规格名称集合 |
| `SpecValues` | string[] | 规格值集合，与 `SpecNames` 一一对应 |
| `Price` | decimal | SKU 价格 |
| `Stock` | int | SKU 库存 |
| `Code` | string | 商家编码 |
| `SpecId` | string | 订单下单用规格 ID |
| `ImageUrl` | string | SKU 图片地址 |

```
wdjlcli goodsupdate submit -s <店铺ID> -t replacesku -o '{"Items":[{"SpecNames":["颜色","尺码"],"SpecValues":["黑色","均码"],"Price":59.9,"Stock":100}]}'
```

---

#### `addsku`（type=18）— 新增SKU

继承 `DiySkuConf`。规格名称需在商品已有 SKU 规格中存在，重复规格项会被跳过。

| 字段 | 类型 | 说明 |
|------|------|------|
| `Items` | object[] | 自定义 SKU 列表（必填），元素字段见下表 |
| `OverLengthHandleMode` | int | 超出字数处理方式，`1` 放弃修改（默认），`2` 删除尾部超出部分 |

`Items` 元素字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `SpecName` | string | 规格名称（必填），如 `颜色`、`尺码` |
| `SpecValues` | string | 规格选项（必填），逗号分隔，如 `蓝色,M码,均码` |
| `PriceMode` | int | 价格设置模式（必填），`0` 随机价格，`1` SKU 最高价（默认），`2` SKU 最低价 |
| `RandomPriceMin` | decimal | 随机价格最小值（`PriceMode=0` 时必填） |
| `RandomPriceMax` | decimal | 随机价格最大值（`PriceMode=0` 时必填） |
| `Stock` | int | 新增 SKU 的统一库存（必填） |
| `ImageMode` | int | 图片设置模式（必填），`0` 使用商品第一张主图，`1` 自定义上传图片，`2` 使用其他 SKU 图，`3` 不添加 SKU 图 |
| `CustomImageUrl` | string | 自定义图片地址（`ImageMode=1` 时必填） |

```
wdjlcli goodsupdate submit -s <店铺ID> -t addsku -o '{"Items":[{"SpecName":"颜色","SpecValues":"浅蓝,深灰","PriceMode":1,"Stock":100,"ImageMode":0}]}'
```

---

#### `mainimage34`（type=19）— 修改3:4主图

在 `mainimage` 四个子配置（`MainImgOrder`/`MainImgReplace`/`MainImgDel`/`MainImgFlipMode`）基础上增加 3:4 生成配置。

| 字段 | 类型 | 说明 |
|------|------|------|
| `GenerateMode` | int | 3:4 主图生成模式，`0` 自定义，`1` 从 1:1 主图生成 3:4 主图 |
| `MainImg34SizeOptions` | object | 3:4 主图处理方式（`GenerateMode=1` 时必填），字段：`SizeOption`（`0` 1440x1920，`1` 750x1000）、`ProcessMode`（`0` 填充，`1` 裁剪，`2` 拉伸）、`RegenerateExisting`（已有 3:4 主图时是否重新生成） |

```
wdjlcli goodsupdate submit -s <店铺ID> -t mainimage34 -o '{"GenerateMode":1,"MainImg34SizeOptions":{"SizeOption":0,"ProcessMode":0,"RegenerateExisting":false}}'
```

---

#### `detailimage`（type=20）— 修改详情图

| 字段 | 类型 | 说明 |
|------|------|------|
| `DetailImgDel` | object | 删除详情图配置，字段：`DeleteIndex`（删除第 X 张）、`DeleteHeadCount`/`DeleteTailCount`（删前/后 X 张）、`KeepCount`（仅保留 X 张） |
| `DetailImgInsert` | object | 插入详情图配置，字段：`InsertMode`（`0` 不插入，`1` 全部 SKU 图插入，`2` 全部主图插入，`3` 指定主图插入）、`InsertMainIndices`（`InsertMode=3` 时必填）、`InsertPositionMode`（`0` 从首，`1` 从尾，`2` 随机） |
| `DetailImgHeight` | object | 详情图高度设置，字段：`SplitMode`（`0` 平台限制为准，`1` 自定义高度）、`CustomeSplitHeight`（`SplitMode=1` 时必填） |
| `DetailCustomHeads` | string[] | 自定义详情首图列表 |
| `DetailCustomTails` | string[] | 自定义详情尾图列表 |
| `IgnoreSourceDetailImgs` | bool | 是否不使用上家商品详情图 |
| `DetailImgShuffle` | bool | 是否随机打乱详情图顺序 |
| `DetailImgFilterSmallImgs` | bool | 是否过滤小图 |
| `DetailImgAutoMerge` | bool | 超过平台限制时是否自动合并详情图 |
| `DetailImgFlip` | bool | 是否翻转详情图 |
| `NoUploadTaobaoMobile` | bool | 是否不上传淘宝手机端详情 |
| `NoUploadTaobaoPC` | bool | 是否不上传淘宝电脑端详情 |

```
# 删除前 2 张详情图，并插入全部 SKU 图到详情尾部
wdjlcli goodsupdate submit -s <店铺ID> -t detailimage -o '{"DetailImgDel":{"DeleteHeadCount":2},"DetailImgInsert":{"InsertMode":1,"InsertPositionMode":1}}'
```

---

#### `mainvideo`（type=21）— 修改主视频

| 字段 | 类型 | 说明 |
|------|------|------|
| `VideoMode` | int | 主图视频设置模式，`0` 自定义视频，`1` 删除主图视频 |
| `CustomVideoUrl` | string | 自定义视频地址（`VideoMode=0` 时必填） |

```
wdjlcli goodsupdate submit -s <店铺ID> -t mainvideo -o '{"VideoMode":0,"CustomVideoUrl":"https://example.com/video.mp4"}'
```

---

#### `guideimage`（type=22）— 修改导购图

| 字段 | 类型 | 说明 |
|------|------|------|
| `RectangleImgMode` | int | 导购图生成模式，`0` 删除，`1` 上传自定义图（默认），`2` 从主图生成 |
| `RectangleImgFromIndex` | int | 生成导购图的来源主图索引（`RectangleImgMode=2` 时必填） |
| `CustomImageUrl` | string | 自定义导购图地址（`RectangleImgMode=1` 时必填） |
| `RegenerateExisting` | bool | 已有导购图时是否重新生成 |

```
wdjlcli goodsupdate submit -s <店铺ID> -t guideimage -o '{"RectangleImgMode":2,"RectangleImgFromIndex":1,"RegenerateExisting":true}'
```

---

#### `whiteimage`（type=23）— 修改白底图

| 字段 | 类型 | 说明 |
|------|------|------|
| `WhiteBgMode` | int | 白底图生成模式，`0` 删除，`1` 上传自定义图（默认），`2` 从主图生成 |
| `WhiteBgFromIndex` | int | 生成白底图的来源主图索引（`WhiteBgMode=2` 时必填） |
| `CustomImageUrl` | string | 自定义白底图地址（`WhiteBgMode=1` 时必填） |

```
wdjlcli goodsupdate submit -s <店铺ID> -t whiteimage -o '{"WhiteBgMode":2,"WhiteBgFromIndex":1}'
```

---

#### `watermark`（type=24）— 修改水印

继承 `WatermarkConf`。

| 字段 | 类型 | 说明 |
|------|------|------|
| `SkuImgWaterOption` | bool | SKU 图是否加水印 |
| `DescImgWaterOption` | bool | 详情图是否加水印 |
| `MainImgWater` | int | 主图应用范围模式，`0` 或空为不加主图水印，`1` 全部主图，`2` 首图，`3` 指定主图 |
| `MainImgWaterIndexList` | int[] | 需要加水印的主图索引列表（`MainImgWater=3` 时必填） |
| `WaterType` | string | 水印类型，`text` 文字，`image` 图片，`border` 边框 |
| `WaterItemConfig` | object | 水印明细参数，字段：`Position`（`lefttop`/`leftbottom`/`righttop`/`rightbottom`/`center`/`topcenter`/`bottomcenter`/`full`/`random`，默认 `rightbottom`）、`Text`（文字水印内容）、`FontName`（默认 `黑体`）、`FontSize`（默认 `12`）、`FontColorRgba`、`IsBold`、`IsTilt`、`ImageUrl`（`WaterType=image` 时必填）、`BorderWaterUrl`（`WaterType=border` 时必填） |

```
# 全部主图加右下角文字水印
wdjlcli goodsupdate submit -s <店铺ID> -t watermark -o '{"MainImgWater":1,"WaterItemConfig":{"WaterType":"text","Text":"旗舰店正品","Position":"rightbottom"}}'
```

---

#### `sizetemplate`（type=25）— 修改尺码表

| 字段 | 类型 | 说明 |
|------|------|------|
| `SizeChartMode` | int | 尺码模板选择方式，`0` 尺码模板名称（默认），`1` 自定义尺码模板图片 |
| `SizeChartTemplateId` | string | 尺码模板 ID |
| `SizeChartTemplate` | string | 尺码模板名称 |
| `SizeChartImg` | string | 尺码模板图片地址（`SizeChartMode=1` 时必填） |

```
# 按模板名称设置尺码表
wdjlcli goodsupdate submit -s <店铺ID> -t sizetemplate -o '{"SizeChartMode":0,"SizeChartTemplate":"女装通用尺码表"}'

# 使用自定义尺码图
wdjlcli goodsupdate submit -s <店铺ID> -t sizetemplate -o '{"SizeChartMode":1,"SizeChartImg":"https://example.com/size.jpg"}'
```

---

#### `freighttemplate`（type=26）— 修改运费模板

| 字段 | 类型 | 说明 |
|------|------|------|
| `ShippingTemplateId` | string | 运费模板 ID |
| `ShippingTemplateName` | string | 运费模板名称 |
| `WeightKg` | decimal | 商品重量千克数 |
| `Volume` | decimal | 商品体积 |

```
wdjlcli goodsupdate submit -s <店铺ID> -t freighttemplate -o '{"ShippingTemplateId":"12345","ShippingTemplateName":"全国包邮","WeightKg":0.5}'
```

---

#### `sevendayreturn`（type=27）— 修改七天无理由配置

| 字段 | 类型 | 说明 |
|------|------|------|
| `SevenDayReturnOption` | int | 七天无理由退货选项值，默认 `1`；`0` 不支持，`1` 支持，`2` 支持（包装未破损），`3` 支持（安装后不支持），`4` 支持（激活后不支持），`5` 支持（使用后不支持），`6` 支持（定制类不支持），`7` 支持（合约类不支持） |

```
wdjlcli goodsupdate submit -s <店铺ID> -t sevendayreturn -o '{"SevenDayReturnOption":1}'
```

---

#### `purchaselimit`（type=28）— 修改限购配置

按平台传入对应子配置，仅传目标店铺所在平台的配置即可。

| 字段 | 类型 | 说明 |
|------|------|------|
| `DouyinLimit` | object | 抖音限购配置：`LimitEnabled`（是否开启）、`MaxCountByUser`（每用户累计限购数）、`MaxCountByOrder`（单笔订单上限）、`MinCountByOrder`（单笔订单下限） |
| `WxShopLimit` | object | 微店限购配置：`LimitEnabled`、`LimitType`（`1` 每日，`2` 每周，`3` 每月，`4` 每年）、`MaxBuyCount`（限购件数） |
| `KsLimit` | object | 快手限购配置：`LimitEnabled`、`MaxCountByUser`、`MaxCountByOrder`、`MinCountByOrder` |
| `XhsLimit` | object | 小红书限购配置：`LimitEnabled`、`MaxCountByUser`、`StartDateTime`（限售周期开始时间）、`EndDateTime`（限售周期结束时间） |

```
# 抖音店铺：每用户限购 2 件，单笔限购 1 件
wdjlcli goodsupdate submit -s <店铺ID> -t purchaselimit -o '{"DouyinLimit":{"LimitEnabled":true,"MaxCountByUser":2,"MaxCountByOrder":1}}'
```

---

## 通用子对象

<a id="skufilter"></a>

#### GoodsUpdateSkuFilterOptions（SKU 筛选条件）

`skucode`、`stock`、`skuname`、`deletesku` 等 SKU 相关操作复用该子对象。

| 字段 | 类型 | 说明 |
|------|------|------|
| `SkuKeyword` | string | SKU 名称关键字，仅支持 1 个关键字 |
| `SkuCode` | string | SKU 编码筛选值，仅支持 1 个编码 |

<a id="mainimgorder"></a>

#### MainImgOrderConf（主图顺序配置）

| 字段 | 类型 | 说明 |
|------|------|------|
| `MainImgOrderMode` | int | `0` 不修改主图顺序，`1` 随机打乱，`2` 自定义顺序 |
| `CustomOrderList` | int[] | 自定义主图顺序列表（`MainImgOrderMode=2` 时必填），元素为图片索引，如 `[1,3,2,4,5]`；`6-10` 序号仅对拼多多生效 |

<a id="mainimgreplace"></a>

#### MainImgReplaceConf（主图替换配置）

| 字段 | 类型 | 说明 |
|------|------|------|
| `ReplaceMode` | int | `0` 不替换，`1` 用 SKU 图替换主图，`2` 指定主图替换自定义图片 |
| `CustomReplaceImages` | object | 自定义替换图片字典（`ReplaceMode=2` 时必填），Key 为主图位置索引 `1-10`，Value 为图片 URL |

<a id="mainimgdel"></a>

#### MainImgDelConf（主图删除配置）

| 字段 | 类型 | 说明 |
|------|------|------|
| `DeleteMode` | int | `0` 不删除，`1` 仅保留 X 张，`2` 删除第 X 张，`3` 删除前 X 张以及后 Y 张 |
| `KeepCount` | int | 仅保留张数（`DeleteMode=1` 时必填） |
| `DeleteSpecificIndex` | int | 删除第几张主图（`DeleteMode=2` 时必填） |
| `DeleteHeadCount` | int | 删除前几张主图（`DeleteMode=3` 时可填） |
| `DeleteTailCount` | int | 删除后几张主图（`DeleteMode=3` 时可填） |

<a id="mainimgflip"></a>

#### MainImgFlipModeConf（主图翻转配置）

| 字段 | 类型 | 说明 |
|------|------|------|
| `FlipMode` | int | `0` 不翻转，`1` 全部主图翻转，`2` 指定主图翻转 |
| `FlipIndices` | int[] | 指定翻转的主图索引列表（`FlipMode=2` 时必填），索引范围通常为 `1-10` |
