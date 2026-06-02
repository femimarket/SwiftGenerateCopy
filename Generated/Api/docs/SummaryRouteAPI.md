# SummaryRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**summary**](SummaryRouteAPI.md#summary) | **POST** /summary | 


# **summary**
```swift
    open class func summary(userId: String, byColumn: SummaryByColumn? = nil, byFields: SummaryByFields? = nil, byId: SummaryById? = nil, delete: SummaryDelete? = nil, paginate: SummaryPaginate? = nil, search: SummarySearch? = nil, update: SummaryUpdate? = nil, upsert: SummaryUpsert? = nil, completion: @escaping (_ data: SummaryServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = summary.ByColumn(column: "column_example", data: [Summary(credit: 123, id: 123, text: "text_example", userId: "userId_example")], value: 123) // SummaryByColumn |  (optional)
let byFields = summary.ByFields(data: [Summary(credit: 123, id: 123, text: "text_example", userId: "userId_example")], fields: [summary.ByFieldsQuery(path: "path_example", value: "value_example")]) // SummaryByFields |  (optional)
let byId = summary.ById(data: Summary(credit: 123, id: 123, text: "text_example", userId: "userId_example"), id: 123) // SummaryById |  (optional)
let delete = summary.Delete(data: [123]) // SummaryDelete |  (optional)
let paginate = summary.Paginate(data: [Summary(credit: 123, id: 123, text: "text_example", userId: "userId_example")], skip: 123, take: 123) // SummaryPaginate |  (optional)
let search = summary.Search(data: [Summary(credit: 123, id: 123, text: "text_example", userId: "userId_example")], query: "query_example") // SummarySearch |  (optional)
let update = summary.Update(data: [Summary(credit: 123, id: 123, text: "text_example", userId: "userId_example")], inputs: [summary.UpdateItem(fields: "TODO", id: 123)]) // SummaryUpdate |  (optional)
let upsert = summary.Upsert(data: [Summary(credit: 123, id: 123, text: "text_example", userId: "userId_example")]) // SummaryUpsert |  (optional)

SummaryRouteAPI.summary(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert) { (response, error) in
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
 **byColumn** | [**SummaryByColumn**](SummaryByColumn.md) |  | [optional] 
 **byFields** | [**SummaryByFields**](SummaryByFields.md) |  | [optional] 
 **byId** | [**SummaryById**](SummaryById.md) |  | [optional] 
 **delete** | [**SummaryDelete**](SummaryDelete.md) |  | [optional] 
 **paginate** | [**SummaryPaginate**](SummaryPaginate.md) |  | [optional] 
 **search** | [**SummarySearch**](SummarySearch.md) |  | [optional] 
 **update** | [**SummaryUpdate**](SummaryUpdate.md) |  | [optional] 
 **upsert** | [**SummaryUpsert**](SummaryUpsert.md) |  | [optional] 

### Return type

[**SummaryServerRequest**](SummaryServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

