# FalZImageTurboRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**falZImageTurbo**](FalZImageTurboRouteAPI.md#falzimageturbo) | **POST** /fal_z_image_turbo | 


# **falZImageTurbo**
```swift
    open class func falZImageTurbo(userId: String, byColumn: FalZImageTurboByColumn? = nil, byFields: FalZImageTurboByFields? = nil, byId: FalZImageTurboById? = nil, delete: FalZImageTurboDelete? = nil, paginate: FalZImageTurboPaginate? = nil, search: FalZImageTurboSearch? = nil, update: FalZImageTurboUpdate? = nil, upsert: FalZImageTurboUpsert? = nil, completion: @escaping (_ data: FalZImageTurboServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = fal_z_image_turbo.ByColumn(column: "column_example", data: [FalZImageTurbo(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: FalZImageTurboStatus(), userId: "userId_example")], value: 123) // FalZImageTurboByColumn |  (optional)
let byFields = fal_z_image_turbo.ByFields(data: [FalZImageTurbo(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: FalZImageTurboStatus(), userId: "userId_example")], fields: [fal_z_image_turbo.ByFieldsQuery(path: "path_example", value: "value_example")]) // FalZImageTurboByFields |  (optional)
let byId = fal_z_image_turbo.ById(data: FalZImageTurbo(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: FalZImageTurboStatus(), userId: "userId_example"), id: 123) // FalZImageTurboById |  (optional)
let delete = fal_z_image_turbo.Delete(data: [123]) // FalZImageTurboDelete |  (optional)
let paginate = fal_z_image_turbo.Paginate(data: [FalZImageTurbo(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: FalZImageTurboStatus(), userId: "userId_example")], skip: 123, take: 123) // FalZImageTurboPaginate |  (optional)
let search = fal_z_image_turbo.Search(data: [FalZImageTurbo(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: FalZImageTurboStatus(), userId: "userId_example")], query: "query_example") // FalZImageTurboSearch |  (optional)
let update = fal_z_image_turbo.Update(data: [FalZImageTurbo(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: FalZImageTurboStatus(), userId: "userId_example")], inputs: [fal_z_image_turbo.UpdateItem(fields: "TODO", id: 123)]) // FalZImageTurboUpdate |  (optional)
let upsert = fal_z_image_turbo.Upsert(data: [FalZImageTurbo(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: FalZImageTurboStatus(), userId: "userId_example")]) // FalZImageTurboUpsert |  (optional)

FalZImageTurboRouteAPI.falZImageTurbo(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert) { (response, error) in
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
 **byColumn** | [**FalZImageTurboByColumn**](FalZImageTurboByColumn.md) |  | [optional] 
 **byFields** | [**FalZImageTurboByFields**](FalZImageTurboByFields.md) |  | [optional] 
 **byId** | [**FalZImageTurboById**](FalZImageTurboById.md) |  | [optional] 
 **delete** | [**FalZImageTurboDelete**](FalZImageTurboDelete.md) |  | [optional] 
 **paginate** | [**FalZImageTurboPaginate**](FalZImageTurboPaginate.md) |  | [optional] 
 **search** | [**FalZImageTurboSearch**](FalZImageTurboSearch.md) |  | [optional] 
 **update** | [**FalZImageTurboUpdate**](FalZImageTurboUpdate.md) |  | [optional] 
 **upsert** | [**FalZImageTurboUpsert**](FalZImageTurboUpsert.md) |  | [optional] 

### Return type

[**FalZImageTurboServerRequest**](FalZImageTurboServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

