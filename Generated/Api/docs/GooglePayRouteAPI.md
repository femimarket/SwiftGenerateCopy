# GooglePayRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**googlePay**](GooglePayRouteAPI.md#googlepay) | **POST** /google_pay | 


# **googlePay**
```swift
    open class func googlePay(userId: String, byColumn: GooglePayByColumn? = nil, byFields: GooglePayByFields? = nil, byId: GooglePayById? = nil, delete: GooglePayDelete? = nil, paginate: GooglePayPaginate? = nil, search: GooglePaySearch? = nil, update: GooglePayUpdate? = nil, upsert: GooglePayUpsert? = nil, completion: @escaping (_ data: GooglePayServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = google_pay.ByColumn(column: "column_example", data: [GooglePay(credit: 123, id: 123, loaded: false, orderId: "orderId_example", packageName: "packageName_example", productId: "productId_example", purchaseToken: "purchaseToken_example", status: Status(), userId: "userId_example")], value: 123) // GooglePayByColumn |  (optional)
let byFields = google_pay.ByFields(data: [GooglePay(credit: 123, id: 123, loaded: false, orderId: "orderId_example", packageName: "packageName_example", productId: "productId_example", purchaseToken: "purchaseToken_example", status: Status(), userId: "userId_example")], fields: [google_pay.ByFieldsQuery(path: "path_example", value: "value_example")]) // GooglePayByFields |  (optional)
let byId = google_pay.ById(data: GooglePay(credit: 123, id: 123, loaded: false, orderId: "orderId_example", packageName: "packageName_example", productId: "productId_example", purchaseToken: "purchaseToken_example", status: Status(), userId: "userId_example"), id: 123) // GooglePayById |  (optional)
let delete = google_pay.Delete(data: [123]) // GooglePayDelete |  (optional)
let paginate = google_pay.Paginate(data: [GooglePay(credit: 123, id: 123, loaded: false, orderId: "orderId_example", packageName: "packageName_example", productId: "productId_example", purchaseToken: "purchaseToken_example", status: Status(), userId: "userId_example")], skip: 123, take: 123) // GooglePayPaginate |  (optional)
let search = google_pay.Search(data: [GooglePay(credit: 123, id: 123, loaded: false, orderId: "orderId_example", packageName: "packageName_example", productId: "productId_example", purchaseToken: "purchaseToken_example", status: Status(), userId: "userId_example")], query: "query_example") // GooglePaySearch |  (optional)
let update = google_pay.Update(data: [GooglePay(credit: 123, id: 123, loaded: false, orderId: "orderId_example", packageName: "packageName_example", productId: "productId_example", purchaseToken: "purchaseToken_example", status: Status(), userId: "userId_example")], inputs: [google_pay.UpdateItem(fields: "TODO", id: 123)]) // GooglePayUpdate |  (optional)
let upsert = google_pay.Upsert(data: [GooglePay(credit: 123, id: 123, loaded: false, orderId: "orderId_example", packageName: "packageName_example", productId: "productId_example", purchaseToken: "purchaseToken_example", status: Status(), userId: "userId_example")]) // GooglePayUpsert |  (optional)

GooglePayRouteAPI.googlePay(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert) { (response, error) in
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
 **byColumn** | [**GooglePayByColumn**](GooglePayByColumn.md) |  | [optional] 
 **byFields** | [**GooglePayByFields**](GooglePayByFields.md) |  | [optional] 
 **byId** | [**GooglePayById**](GooglePayById.md) |  | [optional] 
 **delete** | [**GooglePayDelete**](GooglePayDelete.md) |  | [optional] 
 **paginate** | [**GooglePayPaginate**](GooglePayPaginate.md) |  | [optional] 
 **search** | [**GooglePaySearch**](GooglePaySearch.md) |  | [optional] 
 **update** | [**GooglePayUpdate**](GooglePayUpdate.md) |  | [optional] 
 **upsert** | [**GooglePayUpsert**](GooglePayUpsert.md) |  | [optional] 

### Return type

[**GooglePayServerRequest**](GooglePayServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

