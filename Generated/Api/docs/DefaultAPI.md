# DefaultAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**mediaGate**](DefaultAPI.md#mediagate) | **GET** /{file} | Auth + per-GB debit gate in front of the &#x60;_upload&#x60; ServeDir on femi.market.   - not a media file → pass through (static site, app data, 404), free   - media file that isn&#39;t a real file in &#x60;_upload&#x60; → pass through, free   - media file in &#x60;_upload&#x60; → require Bearer, charge &#x60;size × pricing.gb&#x60;,     record a debit in the astc ledger, then let ServeDir stream the bytes. The gate only authorizes/charges; ServeDir still does the actual file streaming (range requests, mime, etc.).


# **mediaGate**
```swift
    open class func mediaGate(file: String, completion: @escaping (_ data: [Int]?, _ error: Error?) -> Void)
```

Auth + per-GB debit gate in front of the `_upload` ServeDir on femi.market.   - not a media file → pass through (static site, app data, 404), free   - media file that isn't a real file in `_upload` → pass through, free   - media file in `_upload` → require Bearer, charge `size × pricing.gb`,     record a debit in the astc ledger, then let ServeDir stream the bytes. The gate only authorizes/charges; ServeDir still does the actual file streaming (range requests, mime, etc.).

`#[utoipa::path]` here is doc-only — the fn runs as `from_fn` middleware, not a route handler, but the attribute still emits the spec entry so the generated clients get a typed `downloadMedia(file)`. `servers(...)` pins it to femi.market (the global server is api.earnfemi.com); `Request`/`Next` args aren't documentable extractors so utoipa ignores them and uses the explicit `params`.

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let file = "file_example" // String | media filename in _upload

// Auth + per-GB debit gate in front of the `_upload` ServeDir on femi.market.   - not a media file → pass through (static site, app data, 404), free   - media file that isn't a real file in `_upload` → pass through, free   - media file in `_upload` → require Bearer, charge `size × pricing.gb`,     record a debit in the astc ledger, then let ServeDir stream the bytes. The gate only authorizes/charges; ServeDir still does the actual file streaming (range requests, mime, etc.).
DefaultAPI.mediaGate(file: file) { (response, error) in
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
 **file** | **String** | media filename in _upload | 

### Return type

**[Int]**

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/octet-stream, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

