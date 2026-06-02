# ApiKeyRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**apiKey**](ApiKeyRouteAPI.md#apikey) | **POST** /api_key | 


# **apiKey**
```swift
    open class func apiKey(userId: String, byColumn: ApiKeyByColumn? = nil, byFields: ApiKeyByFields? = nil, byId: ApiKeyById? = nil, delete: ApiKeyDelete? = nil, paginate: ApiKeyPaginate? = nil, search: ApiKeySearch? = nil, update: ApiKeyUpdate? = nil, upsert: ApiKeyUpsert? = nil, completion: @escaping (_ data: ApiKeyServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = api_key.ByColumn(column: "column_example", data: [ApiKey(id: 123, key: "key_example", userId: "userId_example")], value: 123) // ApiKeyByColumn |  (optional)
let byFields = api_key.ByFields(data: [ApiKey(id: 123, key: "key_example", userId: "userId_example")], fields: [api_key.ByFieldsQuery(path: "path_example", value: "value_example")]) // ApiKeyByFields |  (optional)
let byId = api_key.ById(data: ApiKey(id: 123, key: "key_example", userId: "userId_example"), id: 123) // ApiKeyById |  (optional)
let delete = api_key.Delete(data: [123]) // ApiKeyDelete |  (optional)
let paginate = api_key.Paginate(data: [ApiKey(id: 123, key: "key_example", userId: "userId_example")], skip: 123, take: 123) // ApiKeyPaginate |  (optional)
let search = api_key.Search(data: [ApiKey(id: 123, key: "key_example", userId: "userId_example")], query: "query_example") // ApiKeySearch |  (optional)
let update = api_key.Update(data: [ApiKey(id: 123, key: "key_example", userId: "userId_example")], inputs: [api_key.UpdateItem(fields: "TODO", id: 123)]) // ApiKeyUpdate |  (optional)
let upsert = api_key.Upsert(data: [ApiKey(id: 123, key: "key_example", userId: "userId_example")]) // ApiKeyUpsert |  (optional)

ApiKeyRouteAPI.apiKey(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert) { (response, error) in
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
 **byColumn** | [**ApiKeyByColumn**](ApiKeyByColumn.md) |  | [optional] 
 **byFields** | [**ApiKeyByFields**](ApiKeyByFields.md) |  | [optional] 
 **byId** | [**ApiKeyById**](ApiKeyById.md) |  | [optional] 
 **delete** | [**ApiKeyDelete**](ApiKeyDelete.md) |  | [optional] 
 **paginate** | [**ApiKeyPaginate**](ApiKeyPaginate.md) |  | [optional] 
 **search** | [**ApiKeySearch**](ApiKeySearch.md) |  | [optional] 
 **update** | [**ApiKeyUpdate**](ApiKeyUpdate.md) |  | [optional] 
 **upsert** | [**ApiKeyUpsert**](ApiKeyUpsert.md) |  | [optional] 

### Return type

[**ApiKeyServerRequest**](ApiKeyServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

