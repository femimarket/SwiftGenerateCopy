# MicroPixVegaRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**microPixVega**](MicroPixVegaRouteAPI.md#micropixvega) | **POST** /micro_pix_vega | 


# **microPixVega**
```swift
    open class func microPixVega(userId: String, byColumn: MicroPixVegaByColumn? = nil, byFields: MicroPixVegaByFields? = nil, byId: MicroPixVegaById? = nil, delete: MicroPixVegaDelete? = nil, paginate: MicroPixVegaPaginate? = nil, search: MicroPixVegaSearch? = nil, update: MicroPixVegaUpdate? = nil, upsert: MicroPixVegaUpsert? = nil, completion: @escaping (_ data: MicroPixVegaServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = micro_pix_vega.ByColumn(column: "column_example", data: [MicroPixVega(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: Status(), userId: "userId_example")], value: 123) // MicroPixVegaByColumn |  (optional)
let byFields = micro_pix_vega.ByFields(data: [MicroPixVega(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: Status(), userId: "userId_example")], fields: [micro_pix_vega.ByFieldsQuery(path: "path_example", value: "value_example")]) // MicroPixVegaByFields |  (optional)
let byId = micro_pix_vega.ById(data: MicroPixVega(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: Status(), userId: "userId_example"), id: 123) // MicroPixVegaById |  (optional)
let delete = micro_pix_vega.Delete(data: [123]) // MicroPixVegaDelete |  (optional)
let paginate = micro_pix_vega.Paginate(data: [MicroPixVega(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: Status(), userId: "userId_example")], skip: 123, take: 123) // MicroPixVegaPaginate |  (optional)
let search = micro_pix_vega.Search(data: [MicroPixVega(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: Status(), userId: "userId_example")], query: "query_example") // MicroPixVegaSearch |  (optional)
let update = micro_pix_vega.Update(data: [MicroPixVega(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: Status(), userId: "userId_example")], inputs: [micro_pix_vega.UpdateItem(fields: "TODO", id: 123)]) // MicroPixVegaUpdate |  (optional)
let upsert = micro_pix_vega.Upsert(data: [MicroPixVega(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: Status(), userId: "userId_example")]) // MicroPixVegaUpsert |  (optional)

MicroPixVegaRouteAPI.microPixVega(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert) { (response, error) in
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
 **byColumn** | [**MicroPixVegaByColumn**](MicroPixVegaByColumn.md) |  | [optional] 
 **byFields** | [**MicroPixVegaByFields**](MicroPixVegaByFields.md) |  | [optional] 
 **byId** | [**MicroPixVegaById**](MicroPixVegaById.md) |  | [optional] 
 **delete** | [**MicroPixVegaDelete**](MicroPixVegaDelete.md) |  | [optional] 
 **paginate** | [**MicroPixVegaPaginate**](MicroPixVegaPaginate.md) |  | [optional] 
 **search** | [**MicroPixVegaSearch**](MicroPixVegaSearch.md) |  | [optional] 
 **update** | [**MicroPixVegaUpdate**](MicroPixVegaUpdate.md) |  | [optional] 
 **upsert** | [**MicroPixVegaUpsert**](MicroPixVegaUpsert.md) |  | [optional] 

### Return type

[**MicroPixVegaServerRequest**](MicroPixVegaServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

