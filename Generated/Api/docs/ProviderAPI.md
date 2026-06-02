# ProviderAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**providerRoute**](ProviderAPI.md#providerroute) | **POST** /provider_route | 


# **providerRoute**
```swift
    open class func providerRoute(id: UUID, elevenLabs: String? = nil, femi: String? = nil, completion: @escaping (_ data: Provider?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let id = 987 // UUID | 
let elevenLabs = "elevenLabs_example" // String |  (optional)
let femi = "femi_example" // String |  (optional)

ProviderAPI.providerRoute(id: id, elevenLabs: elevenLabs, femi: femi) { (response, error) in
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
 **id** | **UUID** |  | 
 **elevenLabs** | **String** |  | [optional] 
 **femi** | **String** |  | [optional] 

### Return type

[**Provider**](Provider.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

