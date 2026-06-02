# ImageRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**image**](ImageRouteAPI.md#image) | **POST** /image | 


# **image**
```swift
    open class func image(userId: String, byColumn: ImageByColumn? = nil, byFields: ImageByFields? = nil, byId: ImageById? = nil, delete: ImageDelete? = nil, paginate: ImagePaginate? = nil, search: ImageSearch? = nil, update: ImageUpdate? = nil, upsert: ImageUpsert? = nil, completion: @escaping (_ data: ImageServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = image.ByColumn(column: "column_example", data: [Image(credit: 123, file: "file_example", id: 123, userId: "userId_example")], value: 123) // ImageByColumn |  (optional)
let byFields = image.ByFields(data: [Image(credit: 123, file: "file_example", id: 123, userId: "userId_example")], fields: [image.ByFieldsQuery(path: "path_example", value: "value_example")]) // ImageByFields |  (optional)
let byId = image.ById(data: Image(credit: 123, file: "file_example", id: 123, userId: "userId_example"), id: 123) // ImageById |  (optional)
let delete = image.Delete(data: [123]) // ImageDelete |  (optional)
let paginate = image.Paginate(data: [Image(credit: 123, file: "file_example", id: 123, userId: "userId_example")], skip: 123, take: 123) // ImagePaginate |  (optional)
let search = image.Search(data: [Image(credit: 123, file: "file_example", id: 123, userId: "userId_example")], query: "query_example") // ImageSearch |  (optional)
let update = image.Update(data: [Image(credit: 123, file: "file_example", id: 123, userId: "userId_example")], inputs: [image.UpdateItem(fields: "TODO", id: 123)]) // ImageUpdate |  (optional)
let upsert = image.Upsert(data: [Image(credit: 123, file: "file_example", id: 123, userId: "userId_example")]) // ImageUpsert |  (optional)

ImageRouteAPI.image(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert) { (response, error) in
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
 **byColumn** | [**ImageByColumn**](ImageByColumn.md) |  | [optional] 
 **byFields** | [**ImageByFields**](ImageByFields.md) |  | [optional] 
 **byId** | [**ImageById**](ImageById.md) |  | [optional] 
 **delete** | [**ImageDelete**](ImageDelete.md) |  | [optional] 
 **paginate** | [**ImagePaginate**](ImagePaginate.md) |  | [optional] 
 **search** | [**ImageSearch**](ImageSearch.md) |  | [optional] 
 **update** | [**ImageUpdate**](ImageUpdate.md) |  | [optional] 
 **upsert** | [**ImageUpsert**](ImageUpsert.md) |  | [optional] 

### Return type

[**ImageServerRequest**](ImageServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

