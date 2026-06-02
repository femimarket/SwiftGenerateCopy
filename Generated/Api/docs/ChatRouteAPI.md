# ChatRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**chat**](ChatRouteAPI.md#chat) | **POST** /chat | 


# **chat**
```swift
    open class func chat(userId: String, byColumn: ChatByColumn? = nil, byFields: ChatByFields? = nil, byId: ChatById? = nil, delete: ChatDelete? = nil, paginate: ChatPaginate? = nil, search: ChatSearch? = nil, update: ChatUpdate? = nil, upsert: ChatUpsert? = nil, completion: @escaping (_ data: ChatServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = chat.ByColumn(column: "column_example", data: [Chat(credit: 123, id: 123, messages: [ChatMessage(content: "content_example", role: Role())], userId: "userId_example")], value: 123) // ChatByColumn |  (optional)
let byFields = chat.ByFields(data: [Chat(credit: 123, id: 123, messages: [ChatMessage(content: "content_example", role: Role())], userId: "userId_example")], fields: [chat.ByFieldsQuery(path: "path_example", value: "value_example")]) // ChatByFields |  (optional)
let byId = chat.ById(data: Chat(credit: 123, id: 123, messages: [ChatMessage(content: "content_example", role: Role())], userId: "userId_example"), id: 123) // ChatById |  (optional)
let delete = chat.Delete(data: [123]) // ChatDelete |  (optional)
let paginate = chat.Paginate(data: [Chat(credit: 123, id: 123, messages: [ChatMessage(content: "content_example", role: Role())], userId: "userId_example")], skip: 123, take: 123) // ChatPaginate |  (optional)
let search = chat.Search(data: [Chat(credit: 123, id: 123, messages: [ChatMessage(content: "content_example", role: Role())], userId: "userId_example")], query: "query_example") // ChatSearch |  (optional)
let update = chat.Update(data: [Chat(credit: 123, id: 123, messages: [ChatMessage(content: "content_example", role: Role())], userId: "userId_example")], inputs: [chat.UpdateItem(fields: "TODO", id: 123)]) // ChatUpdate |  (optional)
let upsert = chat.Upsert(data: [Chat(credit: 123, id: 123, messages: [ChatMessage(content: "content_example", role: Role())], userId: "userId_example")]) // ChatUpsert |  (optional)

ChatRouteAPI.chat(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert) { (response, error) in
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
 **byColumn** | [**ChatByColumn**](ChatByColumn.md) |  | [optional] 
 **byFields** | [**ChatByFields**](ChatByFields.md) |  | [optional] 
 **byId** | [**ChatById**](ChatById.md) |  | [optional] 
 **delete** | [**ChatDelete**](ChatDelete.md) |  | [optional] 
 **paginate** | [**ChatPaginate**](ChatPaginate.md) |  | [optional] 
 **search** | [**ChatSearch**](ChatSearch.md) |  | [optional] 
 **update** | [**ChatUpdate**](ChatUpdate.md) |  | [optional] 
 **upsert** | [**ChatUpsert**](ChatUpsert.md) |  | [optional] 

### Return type

[**ChatServerRequest**](ChatServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

