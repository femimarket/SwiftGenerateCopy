# RevolutRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**revolut**](RevolutRouteAPI.md#revolut) | **POST** /revolut | 


# **revolut**
```swift
    open class func revolut(userId: String, byColumn: RevolutByColumn? = nil, byFields: RevolutByFields? = nil, byId: RevolutById? = nil, delete: RevolutDelete? = nil, paginate: RevolutPaginate? = nil, search: RevolutSearch? = nil, update: RevolutUpdate? = nil, upsert: RevolutUpsert? = nil, completion: @escaping (_ data: RevolutServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = revolut.ByColumn(column: "column_example", data: [Revolut(amountCents: 123, credit: 123, id: 123, loaded: false, paymentUrl: "paymentUrl_example", revolutOrderId: "revolutOrderId_example", status: Status(), userId: "userId_example")], value: 123) // RevolutByColumn |  (optional)
let byFields = revolut.ByFields(data: [Revolut(amountCents: 123, credit: 123, id: 123, loaded: false, paymentUrl: "paymentUrl_example", revolutOrderId: "revolutOrderId_example", status: Status(), userId: "userId_example")], fields: [revolut.ByFieldsQuery(path: "path_example", value: "value_example")]) // RevolutByFields |  (optional)
let byId = revolut.ById(data: Revolut(amountCents: 123, credit: 123, id: 123, loaded: false, paymentUrl: "paymentUrl_example", revolutOrderId: "revolutOrderId_example", status: Status(), userId: "userId_example"), id: 123) // RevolutById |  (optional)
let delete = revolut.Delete(data: [123]) // RevolutDelete |  (optional)
let paginate = revolut.Paginate(data: [Revolut(amountCents: 123, credit: 123, id: 123, loaded: false, paymentUrl: "paymentUrl_example", revolutOrderId: "revolutOrderId_example", status: Status(), userId: "userId_example")], skip: 123, take: 123) // RevolutPaginate |  (optional)
let search = revolut.Search(data: [Revolut(amountCents: 123, credit: 123, id: 123, loaded: false, paymentUrl: "paymentUrl_example", revolutOrderId: "revolutOrderId_example", status: Status(), userId: "userId_example")], query: "query_example") // RevolutSearch |  (optional)
let update = revolut.Update(data: [Revolut(amountCents: 123, credit: 123, id: 123, loaded: false, paymentUrl: "paymentUrl_example", revolutOrderId: "revolutOrderId_example", status: Status(), userId: "userId_example")], inputs: [revolut.UpdateItem(fields: "TODO", id: 123)]) // RevolutUpdate |  (optional)
let upsert = revolut.Upsert(data: [Revolut(amountCents: 123, credit: 123, id: 123, loaded: false, paymentUrl: "paymentUrl_example", revolutOrderId: "revolutOrderId_example", status: Status(), userId: "userId_example")]) // RevolutUpsert |  (optional)

RevolutRouteAPI.revolut(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert) { (response, error) in
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
 **byColumn** | [**RevolutByColumn**](RevolutByColumn.md) |  | [optional] 
 **byFields** | [**RevolutByFields**](RevolutByFields.md) |  | [optional] 
 **byId** | [**RevolutById**](RevolutById.md) |  | [optional] 
 **delete** | [**RevolutDelete**](RevolutDelete.md) |  | [optional] 
 **paginate** | [**RevolutPaginate**](RevolutPaginate.md) |  | [optional] 
 **search** | [**RevolutSearch**](RevolutSearch.md) |  | [optional] 
 **update** | [**RevolutUpdate**](RevolutUpdate.md) |  | [optional] 
 **upsert** | [**RevolutUpsert**](RevolutUpsert.md) |  | [optional] 

### Return type

[**RevolutServerRequest**](RevolutServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

