# NanoRenSpicaRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**nanoRenSpica**](NanoRenSpicaRouteAPI.md#nanorenspica) | **POST** /nano_ren_spica | 


# **nanoRenSpica**
```swift
    open class func nanoRenSpica(userId: String, byColumn: NanoRenSpicaByColumn? = nil, byFields: NanoRenSpicaByFields? = nil, byId: NanoRenSpicaById? = nil, delete: NanoRenSpicaDelete? = nil, paginate: NanoRenSpicaPaginate? = nil, search: NanoRenSpicaSearch? = nil, update: NanoRenSpicaUpdate? = nil, upsert: NanoRenSpicaUpsert? = nil, completion: @escaping (_ data: NanoRenSpicaServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = nano_ren_spica.ByColumn(column: "column_example", data: [NanoRenSpica(audio: "audio_example", credit: 123, file: "file_example", id: 123, image: "image_example", prompt: "prompt_example", requestId: "requestId_example", status: Status(), userId: "userId_example")], value: 123) // NanoRenSpicaByColumn |  (optional)
let byFields = nano_ren_spica.ByFields(data: [NanoRenSpica(audio: "audio_example", credit: 123, file: "file_example", id: 123, image: "image_example", prompt: "prompt_example", requestId: "requestId_example", status: Status(), userId: "userId_example")], fields: [nano_ren_spica.ByFieldsQuery(path: "path_example", value: "value_example")]) // NanoRenSpicaByFields |  (optional)
let byId = nano_ren_spica.ById(data: NanoRenSpica(audio: "audio_example", credit: 123, file: "file_example", id: 123, image: "image_example", prompt: "prompt_example", requestId: "requestId_example", status: Status(), userId: "userId_example"), id: 123) // NanoRenSpicaById |  (optional)
let delete = nano_ren_spica.Delete(data: [123]) // NanoRenSpicaDelete |  (optional)
let paginate = nano_ren_spica.Paginate(data: [NanoRenSpica(audio: "audio_example", credit: 123, file: "file_example", id: 123, image: "image_example", prompt: "prompt_example", requestId: "requestId_example", status: Status(), userId: "userId_example")], skip: 123, take: 123) // NanoRenSpicaPaginate |  (optional)
let search = nano_ren_spica.Search(data: [NanoRenSpica(audio: "audio_example", credit: 123, file: "file_example", id: 123, image: "image_example", prompt: "prompt_example", requestId: "requestId_example", status: Status(), userId: "userId_example")], query: "query_example") // NanoRenSpicaSearch |  (optional)
let update = nano_ren_spica.Update(data: [NanoRenSpica(audio: "audio_example", credit: 123, file: "file_example", id: 123, image: "image_example", prompt: "prompt_example", requestId: "requestId_example", status: Status(), userId: "userId_example")], inputs: [nano_ren_spica.UpdateItem(fields: "TODO", id: 123)]) // NanoRenSpicaUpdate |  (optional)
let upsert = nano_ren_spica.Upsert(data: [NanoRenSpica(audio: "audio_example", credit: 123, file: "file_example", id: 123, image: "image_example", prompt: "prompt_example", requestId: "requestId_example", status: Status(), userId: "userId_example")]) // NanoRenSpicaUpsert |  (optional)

NanoRenSpicaRouteAPI.nanoRenSpica(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert) { (response, error) in
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
 **byColumn** | [**NanoRenSpicaByColumn**](NanoRenSpicaByColumn.md) |  | [optional] 
 **byFields** | [**NanoRenSpicaByFields**](NanoRenSpicaByFields.md) |  | [optional] 
 **byId** | [**NanoRenSpicaById**](NanoRenSpicaById.md) |  | [optional] 
 **delete** | [**NanoRenSpicaDelete**](NanoRenSpicaDelete.md) |  | [optional] 
 **paginate** | [**NanoRenSpicaPaginate**](NanoRenSpicaPaginate.md) |  | [optional] 
 **search** | [**NanoRenSpicaSearch**](NanoRenSpicaSearch.md) |  | [optional] 
 **update** | [**NanoRenSpicaUpdate**](NanoRenSpicaUpdate.md) |  | [optional] 
 **upsert** | [**NanoRenSpicaUpsert**](NanoRenSpicaUpsert.md) |  | [optional] 

### Return type

[**NanoRenSpicaServerRequest**](NanoRenSpicaServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

