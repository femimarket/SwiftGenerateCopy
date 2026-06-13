# NanoPixLunaRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**nanoPixLuna**](NanoPixLunaRouteAPI.md#nanopixluna) | **POST** /nano_pix_luna | 


# **nanoPixLuna**
```swift
    open class func nanoPixLuna(userId: String, byColumn: NanoPixLunaByColumn? = nil, byFields: NanoPixLunaByFields? = nil, byId: NanoPixLunaById? = nil, delete: NanoPixLunaDelete? = nil, paginate: NanoPixLunaPaginate? = nil, search: NanoPixLunaSearch? = nil, update: NanoPixLunaUpdate? = nil, upsert: NanoPixLunaUpsert? = nil, upsert1: NanoPixLunaUpsert1? = nil, completion: @escaping (_ data: NanoPixLunaServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = nano_pix_luna.ByColumn(column: "column_example", data: [NanoPixLuna(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: NanoPixLunaStatus(), userId: "userId_example")], value: 123) // NanoPixLunaByColumn |  (optional)
let byFields = nano_pix_luna.ByFields(data: [NanoPixLuna(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: NanoPixLunaStatus(), userId: "userId_example")], fields: [nano_pix_luna.ByFieldsQuery(path: "path_example", value: "value_example")]) // NanoPixLunaByFields |  (optional)
let byId = nano_pix_luna.ById(data: NanoPixLuna(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: NanoPixLunaStatus(), userId: "userId_example"), id: 123) // NanoPixLunaById |  (optional)
let delete = nano_pix_luna.Delete(data: [123]) // NanoPixLunaDelete |  (optional)
let paginate = nano_pix_luna.Paginate(data: [NanoPixLuna(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: NanoPixLunaStatus(), userId: "userId_example")], skip: 123, take: 123) // NanoPixLunaPaginate |  (optional)
let search = nano_pix_luna.Search(data: [NanoPixLuna(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: NanoPixLunaStatus(), userId: "userId_example")], query: "query_example") // NanoPixLunaSearch |  (optional)
let update = nano_pix_luna.Update(data: [NanoPixLuna(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: NanoPixLunaStatus(), userId: "userId_example")], inputs: [nano_pix_luna.UpdateItem(fields: "TODO", id: 123)]) // NanoPixLunaUpdate |  (optional)
let upsert = nano_pix_luna.Upsert(data: [NanoPixLuna(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: NanoPixLunaStatus(), userId: "userId_example")]) // NanoPixLunaUpsert |  (optional)
let upsert1 = nano_pix_luna.Upsert1(data: NanoPixLuna(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: NanoPixLunaStatus(), userId: "userId_example")) // NanoPixLunaUpsert1 |  (optional)

NanoPixLunaRouteAPI.nanoPixLuna(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert, upsert1: upsert1) { (response, error) in
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
 **byColumn** | [**NanoPixLunaByColumn**](NanoPixLunaByColumn.md) |  | [optional] 
 **byFields** | [**NanoPixLunaByFields**](NanoPixLunaByFields.md) |  | [optional] 
 **byId** | [**NanoPixLunaById**](NanoPixLunaById.md) |  | [optional] 
 **delete** | [**NanoPixLunaDelete**](NanoPixLunaDelete.md) |  | [optional] 
 **paginate** | [**NanoPixLunaPaginate**](NanoPixLunaPaginate.md) |  | [optional] 
 **search** | [**NanoPixLunaSearch**](NanoPixLunaSearch.md) |  | [optional] 
 **update** | [**NanoPixLunaUpdate**](NanoPixLunaUpdate.md) |  | [optional] 
 **upsert** | [**NanoPixLunaUpsert**](NanoPixLunaUpsert.md) |  | [optional] 
 **upsert1** | [**NanoPixLunaUpsert1**](NanoPixLunaUpsert1.md) |  | [optional] 

### Return type

[**NanoPixLunaServerRequest**](NanoPixLunaServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

