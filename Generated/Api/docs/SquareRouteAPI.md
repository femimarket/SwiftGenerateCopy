# SquareRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**square**](SquareRouteAPI.md#square) | **POST** /square | 


# **square**
```swift
    open class func square(userId: String, byColumn: SquareByColumn? = nil, byFields: SquareByFields? = nil, byId: SquareById? = nil, delete: SquareDelete? = nil, paginate: SquarePaginate? = nil, search: SquareSearch? = nil, update: SquareUpdate? = nil, upsert: SquareUpsert? = nil, completion: @escaping (_ data: SquareServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = square.ByColumn(column: "column_example", data: [Square(amountCents: 123, credit: 123, id: 123, loaded: false, paymentUrl: "paymentUrl_example", squareOrderId: "squareOrderId_example", squarePaymentId: "squarePaymentId_example", status: Status(), userId: "userId_example")], value: 123) // SquareByColumn |  (optional)
let byFields = square.ByFields(data: [Square(amountCents: 123, credit: 123, id: 123, loaded: false, paymentUrl: "paymentUrl_example", squareOrderId: "squareOrderId_example", squarePaymentId: "squarePaymentId_example", status: Status(), userId: "userId_example")], fields: [square.ByFieldsQuery(path: "path_example", value: "value_example")]) // SquareByFields |  (optional)
let byId = square.ById(data: Square(amountCents: 123, credit: 123, id: 123, loaded: false, paymentUrl: "paymentUrl_example", squareOrderId: "squareOrderId_example", squarePaymentId: "squarePaymentId_example", status: Status(), userId: "userId_example"), id: 123) // SquareById |  (optional)
let delete = square.Delete(data: [123]) // SquareDelete |  (optional)
let paginate = square.Paginate(data: [Square(amountCents: 123, credit: 123, id: 123, loaded: false, paymentUrl: "paymentUrl_example", squareOrderId: "squareOrderId_example", squarePaymentId: "squarePaymentId_example", status: Status(), userId: "userId_example")], skip: 123, take: 123) // SquarePaginate |  (optional)
let search = square.Search(data: [Square(amountCents: 123, credit: 123, id: 123, loaded: false, paymentUrl: "paymentUrl_example", squareOrderId: "squareOrderId_example", squarePaymentId: "squarePaymentId_example", status: Status(), userId: "userId_example")], query: "query_example") // SquareSearch |  (optional)
let update = square.Update(data: [Square(amountCents: 123, credit: 123, id: 123, loaded: false, paymentUrl: "paymentUrl_example", squareOrderId: "squareOrderId_example", squarePaymentId: "squarePaymentId_example", status: Status(), userId: "userId_example")], inputs: [square.UpdateItem(fields: "TODO", id: 123)]) // SquareUpdate |  (optional)
let upsert = square.Upsert(data: [Square(amountCents: 123, credit: 123, id: 123, loaded: false, paymentUrl: "paymentUrl_example", squareOrderId: "squareOrderId_example", squarePaymentId: "squarePaymentId_example", status: Status(), userId: "userId_example")]) // SquareUpsert |  (optional)

SquareRouteAPI.square(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String** |  | 
 **byColumn** | [**SquareByColumn**](SquareByColumn.md) |  | [optional] 
 **byFields** | [**SquareByFields**](SquareByFields.md) |  | [optional] 
 **byId** | [**SquareById**](SquareById.md) |  | [optional] 
 **delete** | [**SquareDelete**](SquareDelete.md) |  | [optional] 
 **paginate** | [**SquarePaginate**](SquarePaginate.md) |  | [optional] 
 **search** | [**SquareSearch**](SquareSearch.md) |  | [optional] 
 **update** | [**SquareUpdate**](SquareUpdate.md) |  | [optional] 
 **upsert** | [**SquareUpsert**](SquareUpsert.md) |  | [optional] 

### Return type

[**SquareServerRequest**](SquareServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

