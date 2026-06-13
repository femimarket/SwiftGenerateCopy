# FalNanoBanana2RouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**falNanoBanana2**](FalNanoBanana2RouteAPI.md#falnanobanana2) | **POST** /fal_nano_banana2 | 


# **falNanoBanana2**
```swift
    open class func falNanoBanana2(userId: String, byColumn: FalNanoBanana2ByColumn? = nil, byFields: FalNanoBanana2ByFields? = nil, byId: FalNanoBanana2ById? = nil, delete: FalNanoBanana2Delete? = nil, paginate: FalNanoBanana2Paginate? = nil, search: FalNanoBanana2Search? = nil, update: FalNanoBanana2Update? = nil, upsert: FalNanoBanana2Upsert? = nil, completion: @escaping (_ data: FalNanoBanana2ServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = fal_nano_banana2.ByColumn(column: "column_example", data: [FalNanoBanana2(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: FalNanoBanana2Status(), userId: "userId_example")], value: 123) // FalNanoBanana2ByColumn |  (optional)
let byFields = fal_nano_banana2.ByFields(data: [FalNanoBanana2(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: FalNanoBanana2Status(), userId: "userId_example")], fields: [fal_nano_banana2.ByFieldsQuery(path: "path_example", value: "value_example")]) // FalNanoBanana2ByFields |  (optional)
let byId = fal_nano_banana2.ById(data: FalNanoBanana2(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: FalNanoBanana2Status(), userId: "userId_example"), id: 123) // FalNanoBanana2ById |  (optional)
let delete = fal_nano_banana2.Delete(data: [123]) // FalNanoBanana2Delete |  (optional)
let paginate = fal_nano_banana2.Paginate(data: [FalNanoBanana2(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: FalNanoBanana2Status(), userId: "userId_example")], skip: 123, take: 123) // FalNanoBanana2Paginate |  (optional)
let search = fal_nano_banana2.Search(data: [FalNanoBanana2(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: FalNanoBanana2Status(), userId: "userId_example")], query: "query_example") // FalNanoBanana2Search |  (optional)
let update = fal_nano_banana2.Update(data: [FalNanoBanana2(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: FalNanoBanana2Status(), userId: "userId_example")], inputs: [fal_nano_banana2.UpdateItem(fields: "TODO", id: 123)]) // FalNanoBanana2Update |  (optional)
let upsert = fal_nano_banana2.Upsert(data: [FalNanoBanana2(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: FalNanoBanana2Status(), userId: "userId_example")]) // FalNanoBanana2Upsert |  (optional)

FalNanoBanana2RouteAPI.falNanoBanana2(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert) { (response, error) in
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
 **byColumn** | [**FalNanoBanana2ByColumn**](FalNanoBanana2ByColumn.md) |  | [optional] 
 **byFields** | [**FalNanoBanana2ByFields**](FalNanoBanana2ByFields.md) |  | [optional] 
 **byId** | [**FalNanoBanana2ById**](FalNanoBanana2ById.md) |  | [optional] 
 **delete** | [**FalNanoBanana2Delete**](FalNanoBanana2Delete.md) |  | [optional] 
 **paginate** | [**FalNanoBanana2Paginate**](FalNanoBanana2Paginate.md) |  | [optional] 
 **search** | [**FalNanoBanana2Search**](FalNanoBanana2Search.md) |  | [optional] 
 **update** | [**FalNanoBanana2Update**](FalNanoBanana2Update.md) |  | [optional] 
 **upsert** | [**FalNanoBanana2Upsert**](FalNanoBanana2Upsert.md) |  | [optional] 

### Return type

[**FalNanoBanana2ServerRequest**](FalNanoBanana2ServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

