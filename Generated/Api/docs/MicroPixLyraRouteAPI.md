# MicroPixLyraRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**microPixLyra**](MicroPixLyraRouteAPI.md#micropixlyra) | **POST** /micro_pix_lyra | 


# **microPixLyra**
```swift
    open class func microPixLyra(userId: String, byColumn: MicroPixLyraByColumn? = nil, byFields: MicroPixLyraByFields? = nil, byId: MicroPixLyraById? = nil, delete: MicroPixLyraDelete? = nil, paginate: MicroPixLyraPaginate? = nil, search: MicroPixLyraSearch? = nil, update: MicroPixLyraUpdate? = nil, upsert: MicroPixLyraUpsert? = nil, completion: @escaping (_ data: MicroPixLyraServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = micro_pix_lyra.ByColumn(column: "column_example", data: [MicroPixLyra(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: Status(), userId: "userId_example")], value: 123) // MicroPixLyraByColumn |  (optional)
let byFields = micro_pix_lyra.ByFields(data: [MicroPixLyra(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: Status(), userId: "userId_example")], fields: [micro_pix_lyra.ByFieldsQuery(path: "path_example", value: "value_example")]) // MicroPixLyraByFields |  (optional)
let byId = micro_pix_lyra.ById(data: MicroPixLyra(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: Status(), userId: "userId_example"), id: 123) // MicroPixLyraById |  (optional)
let delete = micro_pix_lyra.Delete(data: [123]) // MicroPixLyraDelete |  (optional)
let paginate = micro_pix_lyra.Paginate(data: [MicroPixLyra(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: Status(), userId: "userId_example")], skip: 123, take: 123) // MicroPixLyraPaginate |  (optional)
let search = micro_pix_lyra.Search(data: [MicroPixLyra(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: Status(), userId: "userId_example")], query: "query_example") // MicroPixLyraSearch |  (optional)
let update = micro_pix_lyra.Update(data: [MicroPixLyra(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: Status(), userId: "userId_example")], inputs: [micro_pix_lyra.UpdateItem(fields: "TODO", id: 123)]) // MicroPixLyraUpdate |  (optional)
let upsert = micro_pix_lyra.Upsert(data: [MicroPixLyra(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: Status(), userId: "userId_example")]) // MicroPixLyraUpsert |  (optional)

MicroPixLyraRouteAPI.microPixLyra(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert) { (response, error) in
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
 **byColumn** | [**MicroPixLyraByColumn**](MicroPixLyraByColumn.md) |  | [optional] 
 **byFields** | [**MicroPixLyraByFields**](MicroPixLyraByFields.md) |  | [optional] 
 **byId** | [**MicroPixLyraById**](MicroPixLyraById.md) |  | [optional] 
 **delete** | [**MicroPixLyraDelete**](MicroPixLyraDelete.md) |  | [optional] 
 **paginate** | [**MicroPixLyraPaginate**](MicroPixLyraPaginate.md) |  | [optional] 
 **search** | [**MicroPixLyraSearch**](MicroPixLyraSearch.md) |  | [optional] 
 **update** | [**MicroPixLyraUpdate**](MicroPixLyraUpdate.md) |  | [optional] 
 **upsert** | [**MicroPixLyraUpsert**](MicroPixLyraUpsert.md) |  | [optional] 

### Return type

[**MicroPixLyraServerRequest**](MicroPixLyraServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

