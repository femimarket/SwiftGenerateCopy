# QuestionRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**question**](QuestionRouteAPI.md#question) | **POST** /question | 


# **question**
```swift
    open class func question(userId: String, byColumn: QuestionByColumn? = nil, byFields: QuestionByFields? = nil, byId: QuestionById? = nil, delete: QuestionDelete? = nil, paginate: QuestionPaginate? = nil, search: QuestionSearch? = nil, update: QuestionUpdate? = nil, upsert: QuestionUpsert? = nil, completion: @escaping (_ data: QuestionServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = question.ByColumn(column: "column_example", data: [Question(credit: 123, id: 123, text: "text_example", userId: "userId_example")], value: 123) // QuestionByColumn |  (optional)
let byFields = question.ByFields(data: [Question(credit: 123, id: 123, text: "text_example", userId: "userId_example")], fields: [question.ByFieldsQuery(path: "path_example", value: "value_example")]) // QuestionByFields |  (optional)
let byId = question.ById(data: Question(credit: 123, id: 123, text: "text_example", userId: "userId_example"), id: 123) // QuestionById |  (optional)
let delete = question.Delete(data: [123]) // QuestionDelete |  (optional)
let paginate = question.Paginate(data: [Question(credit: 123, id: 123, text: "text_example", userId: "userId_example")], skip: 123, take: 123) // QuestionPaginate |  (optional)
let search = question.Search(data: [Question(credit: 123, id: 123, text: "text_example", userId: "userId_example")], query: "query_example") // QuestionSearch |  (optional)
let update = question.Update(data: [Question(credit: 123, id: 123, text: "text_example", userId: "userId_example")], inputs: [question.UpdateItem(fields: "TODO", id: 123)]) // QuestionUpdate |  (optional)
let upsert = question.Upsert(data: [Question(credit: 123, id: 123, text: "text_example", userId: "userId_example")]) // QuestionUpsert |  (optional)

QuestionRouteAPI.question(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert) { (response, error) in
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
 **byColumn** | [**QuestionByColumn**](QuestionByColumn.md) |  | [optional] 
 **byFields** | [**QuestionByFields**](QuestionByFields.md) |  | [optional] 
 **byId** | [**QuestionById**](QuestionById.md) |  | [optional] 
 **delete** | [**QuestionDelete**](QuestionDelete.md) |  | [optional] 
 **paginate** | [**QuestionPaginate**](QuestionPaginate.md) |  | [optional] 
 **search** | [**QuestionSearch**](QuestionSearch.md) |  | [optional] 
 **update** | [**QuestionUpdate**](QuestionUpdate.md) |  | [optional] 
 **upsert** | [**QuestionUpsert**](QuestionUpsert.md) |  | [optional] 

### Return type

[**QuestionServerRequest**](QuestionServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

