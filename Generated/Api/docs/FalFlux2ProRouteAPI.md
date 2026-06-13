# FalFlux2ProRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**falFlux2Pro**](FalFlux2ProRouteAPI.md#falflux2pro) | **POST** /fal_flux2_pro | 


# **falFlux2Pro**
```swift
    open class func falFlux2Pro(userId: String, byColumn: FalFlux2ProByColumn? = nil, byFields: FalFlux2ProByFields? = nil, byId: FalFlux2ProById? = nil, delete: FalFlux2ProDelete? = nil, paginate: FalFlux2ProPaginate? = nil, search: FalFlux2ProSearch? = nil, update: FalFlux2ProUpdate? = nil, upsert: FalFlux2ProUpsert? = nil, completion: @escaping (_ data: FalFlux2ProServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = fal_flux2_pro.ByColumn(column: "column_example", data: [FalFlux2Pro(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: FalFlux2ProStatus(), userId: "userId_example")], value: 123) // FalFlux2ProByColumn |  (optional)
let byFields = fal_flux2_pro.ByFields(data: [FalFlux2Pro(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: FalFlux2ProStatus(), userId: "userId_example")], fields: [fal_flux2_pro.ByFieldsQuery(path: "path_example", value: "value_example")]) // FalFlux2ProByFields |  (optional)
let byId = fal_flux2_pro.ById(data: FalFlux2Pro(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: FalFlux2ProStatus(), userId: "userId_example"), id: 123) // FalFlux2ProById |  (optional)
let delete = fal_flux2_pro.Delete(data: [123]) // FalFlux2ProDelete |  (optional)
let paginate = fal_flux2_pro.Paginate(data: [FalFlux2Pro(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: FalFlux2ProStatus(), userId: "userId_example")], skip: 123, take: 123) // FalFlux2ProPaginate |  (optional)
let search = fal_flux2_pro.Search(data: [FalFlux2Pro(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: FalFlux2ProStatus(), userId: "userId_example")], query: "query_example") // FalFlux2ProSearch |  (optional)
let update = fal_flux2_pro.Update(data: [FalFlux2Pro(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: FalFlux2ProStatus(), userId: "userId_example")], inputs: [fal_flux2_pro.UpdateItem(fields: "TODO", id: 123)]) // FalFlux2ProUpdate |  (optional)
let upsert = fal_flux2_pro.Upsert(data: [FalFlux2Pro(credit: 123, file: "file_example", id: 123, prompt: "prompt_example", requestId: "requestId_example", status: FalFlux2ProStatus(), userId: "userId_example")]) // FalFlux2ProUpsert |  (optional)

FalFlux2ProRouteAPI.falFlux2Pro(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert) { (response, error) in
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
 **byColumn** | [**FalFlux2ProByColumn**](FalFlux2ProByColumn.md) |  | [optional] 
 **byFields** | [**FalFlux2ProByFields**](FalFlux2ProByFields.md) |  | [optional] 
 **byId** | [**FalFlux2ProById**](FalFlux2ProById.md) |  | [optional] 
 **delete** | [**FalFlux2ProDelete**](FalFlux2ProDelete.md) |  | [optional] 
 **paginate** | [**FalFlux2ProPaginate**](FalFlux2ProPaginate.md) |  | [optional] 
 **search** | [**FalFlux2ProSearch**](FalFlux2ProSearch.md) |  | [optional] 
 **update** | [**FalFlux2ProUpdate**](FalFlux2ProUpdate.md) |  | [optional] 
 **upsert** | [**FalFlux2ProUpsert**](FalFlux2ProUpsert.md) |  | [optional] 

### Return type

[**FalFlux2ProServerRequest**](FalFlux2ProServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

