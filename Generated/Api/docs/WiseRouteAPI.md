# WiseRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**wise**](WiseRouteAPI.md#wise) | **POST** /wise | 


# **wise**
```swift
    open class func wise(userId: String, byColumn: WiseByColumn? = nil, byFields: WiseByFields? = nil, byId: WiseById? = nil, delete: WiseDelete? = nil, paginate: WisePaginate? = nil, search: WiseSearch? = nil, update: WiseUpdate? = nil, upsert: WiseUpsert? = nil, completion: @escaping (_ data: WiseServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = wise.ByColumn(column: "column_example", data: [Wise(amountCents: 123, credit: 123, currency: "currency_example", id: 123, loaded: false, reference: "reference_example", status: Status(), userId: "userId_example", wiseCreditId: "wiseCreditId_example")], value: 123) // WiseByColumn |  (optional)
let byFields = wise.ByFields(data: [Wise(amountCents: 123, credit: 123, currency: "currency_example", id: 123, loaded: false, reference: "reference_example", status: Status(), userId: "userId_example", wiseCreditId: "wiseCreditId_example")], fields: [wise.ByFieldsQuery(path: "path_example", value: "value_example")]) // WiseByFields |  (optional)
let byId = wise.ById(data: Wise(amountCents: 123, credit: 123, currency: "currency_example", id: 123, loaded: false, reference: "reference_example", status: Status(), userId: "userId_example", wiseCreditId: "wiseCreditId_example"), id: 123) // WiseById |  (optional)
let delete = wise.Delete(data: [123]) // WiseDelete |  (optional)
let paginate = wise.Paginate(data: [Wise(amountCents: 123, credit: 123, currency: "currency_example", id: 123, loaded: false, reference: "reference_example", status: Status(), userId: "userId_example", wiseCreditId: "wiseCreditId_example")], skip: 123, take: 123) // WisePaginate |  (optional)
let search = wise.Search(data: [Wise(amountCents: 123, credit: 123, currency: "currency_example", id: 123, loaded: false, reference: "reference_example", status: Status(), userId: "userId_example", wiseCreditId: "wiseCreditId_example")], query: "query_example") // WiseSearch |  (optional)
let update = wise.Update(data: [Wise(amountCents: 123, credit: 123, currency: "currency_example", id: 123, loaded: false, reference: "reference_example", status: Status(), userId: "userId_example", wiseCreditId: "wiseCreditId_example")], inputs: [wise.UpdateItem(fields: "TODO", id: 123)]) // WiseUpdate |  (optional)
let upsert = wise.Upsert(data: [Wise(amountCents: 123, credit: 123, currency: "currency_example", id: 123, loaded: false, reference: "reference_example", status: Status(), userId: "userId_example", wiseCreditId: "wiseCreditId_example")]) // WiseUpsert |  (optional)

WiseRouteAPI.wise(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert) { (response, error) in
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
 **byColumn** | [**WiseByColumn**](WiseByColumn.md) |  | [optional] 
 **byFields** | [**WiseByFields**](WiseByFields.md) |  | [optional] 
 **byId** | [**WiseById**](WiseById.md) |  | [optional] 
 **delete** | [**WiseDelete**](WiseDelete.md) |  | [optional] 
 **paginate** | [**WisePaginate**](WisePaginate.md) |  | [optional] 
 **search** | [**WiseSearch**](WiseSearch.md) |  | [optional] 
 **update** | [**WiseUpdate**](WiseUpdate.md) |  | [optional] 
 **upsert** | [**WiseUpsert**](WiseUpsert.md) |  | [optional] 

### Return type

[**WiseServerRequest**](WiseServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

