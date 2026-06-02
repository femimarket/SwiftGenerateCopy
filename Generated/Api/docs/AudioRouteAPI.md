# AudioRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**audio**](AudioRouteAPI.md#audio) | **POST** /audio | 


# **audio**
```swift
    open class func audio(userId: String, byColumn: AudioByColumn? = nil, byFields: AudioByFields? = nil, byId: AudioById? = nil, delete: AudioDelete? = nil, paginate: AudioPaginate? = nil, search: AudioSearch? = nil, update: AudioUpdate? = nil, upsert: AudioUpsert? = nil, completion: @escaping (_ data: AudioServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = audio.ByColumn(column: "column_example", data: [Audio(credit: 123, file: "file_example", id: 123, userId: "userId_example")], value: 123) // AudioByColumn |  (optional)
let byFields = audio.ByFields(data: [Audio(credit: 123, file: "file_example", id: 123, userId: "userId_example")], fields: [audio.ByFieldsQuery(path: "path_example", value: "value_example")]) // AudioByFields |  (optional)
let byId = audio.ById(data: Audio(credit: 123, file: "file_example", id: 123, userId: "userId_example"), id: 123) // AudioById |  (optional)
let delete = audio.Delete(data: [123]) // AudioDelete |  (optional)
let paginate = audio.Paginate(data: [Audio(credit: 123, file: "file_example", id: 123, userId: "userId_example")], skip: 123, take: 123) // AudioPaginate |  (optional)
let search = audio.Search(data: [Audio(credit: 123, file: "file_example", id: 123, userId: "userId_example")], query: "query_example") // AudioSearch |  (optional)
let update = audio.Update(data: [Audio(credit: 123, file: "file_example", id: 123, userId: "userId_example")], inputs: [audio.UpdateItem(fields: "TODO", id: 123)]) // AudioUpdate |  (optional)
let upsert = audio.Upsert(data: [Audio(credit: 123, file: "file_example", id: 123, userId: "userId_example")]) // AudioUpsert |  (optional)

AudioRouteAPI.audio(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert) { (response, error) in
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
 **byColumn** | [**AudioByColumn**](AudioByColumn.md) |  | [optional] 
 **byFields** | [**AudioByFields**](AudioByFields.md) |  | [optional] 
 **byId** | [**AudioById**](AudioById.md) |  | [optional] 
 **delete** | [**AudioDelete**](AudioDelete.md) |  | [optional] 
 **paginate** | [**AudioPaginate**](AudioPaginate.md) |  | [optional] 
 **search** | [**AudioSearch**](AudioSearch.md) |  | [optional] 
 **update** | [**AudioUpdate**](AudioUpdate.md) |  | [optional] 
 **upsert** | [**AudioUpsert**](AudioUpsert.md) |  | [optional] 

### Return type

[**AudioServerRequest**](AudioServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

