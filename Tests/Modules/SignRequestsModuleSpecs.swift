//
//  SignRequestsModuleSpecs.swift
//  BoxSDKTests-iOS
//
//  Created by Artur Jankowski on 13/10/2021.
//  Copyright © 2021 box. All rights reserved.
//

@testable import BoxSDK
import Nimble
import OHHTTPStubs
import OHHTTPStubs.NSURLRequest_HTTPBodyTesting
import Quick

class SignRequestsModuleSpecs: QuickSpec {
    var sut: BoxClient!

    override func spec() {
        describe("Sign Requests Module") {
            beforeEach {
                self.sut = BoxSDK.getClient(token: "")
            }

            afterEach {
                OHHTTPStubs.removeAllStubs()
            }

            describe("create()") {

                it("should make API call to create sign request and produce sign request model when call is successful") {
                    stub(
                        condition: isHost("api.box.com")
                            && isPath("/2.0/sign_requests")
                            && isMethodPOST()
                            && hasJsonBody([
                                "signers": [
                                    [
                                        "email": "example@gmail.com",
                                        "role": "signer",
                                        "redirect_url": "https://box.com/redirect_url_signer_1",
                                        "declined_redirect_url": "https://box.com/declined_redirect_url_signer_1"
                                    ]
                                ],
                                "source_files": [["id": "12345", "type": "file"]],
                                "parent_folder": ["type": "folder", "id": "12345"],
                                "is_document_preparation_needed": true,
                                "are_text_signatures_enabled": true,
                                "are_reminders_enabled": true,
                                "prefill_tags": [
                                    ["document_tag_id": "1234", "text_value": "text"],
                                    ["document_tag_id": "4567", "date_value": "2021-12-03"]
                                ],
                                "email_subject": "Sign Request from Acme",
                                "email_message": "Hello! Please sign the document below",
                                "external_id": "123",
                                "days_valid": 2,
                                "redirect_url": "https://box.com/redirect_url",
                                "declined_redirect_url": "https://box.com/declined_redirect_url"
                            ])
                    ) { _ in
                        OHHTTPStubsResponse(
                            fileAtPath: OHPathForFile("CreateSignRequest.json", type(of: self))!,
                            statusCode: 201, headers: ["Content-Type": "application/json"]
                        )
                    }

                    waitUntil(timeout: .seconds(10)) { done in
                        let signers = [SignRequestCreateSigner(
                            email: "example@gmail.com",
                            role: .signer,
                            redirectUrl: "https://box.com/redirect_url_signer_1",
                            declinedRedirectUrl: "https://box.com/declined_redirect_url_signer_1"
                        )]
                        let sourceFiles = [SignRequestCreateSourceFile(id: "12345")]
                        let parentFolder = SignRequestCreateParentFolder(id: "12345")
                        let tags = [
                            SignRequestPrefillTag(documentTagId: "1234", textValue: "text"),
                            SignRequestPrefillTag(documentTagId: "4567", dateValue: "2021-12-03T08:12:13.982Z".iso8601)
                        ]
                        let params = SignRequestCreateParameters(
                            isDocumentPreparationNeeded: true,
                            areTextSignaturesEnabled: true,
                            emailSubject: "Sign Request from Acme",
                            emailMessage: "Hello! Please sign the document below",
                            areRemindersEnabled: true,
                            prefillTags: tags,
                            daysValid: 2,
                            externalId: "123",
                            redirectUrl: "https://box.com/redirect_url",
                            declinedRedirectUrl: "https://box.com/declined_redirect_url"
                        )

                        self.sut.signRequests.create(
                            signers: signers,
                            sourceFiles: sourceFiles,
                            parentFolder: parentFolder,
                            parameters: params
                        ) { result in
                            switch result {
                            case let .success(signRequest):
                                expect(signRequest).toNot(beNil())
                                expect(signRequest.id).to(equal("12345"))
                                expect(signRequest.signers.first?.email).to(equal("example@gmail.com"))
                                expect(signRequest.sourceFiles.first?.id).to(equal("12345"))
                                expect(signRequest.sourceFiles.first?.name).to(equal("Contract.pdf"))
                                expect(signRequest.parentFolder.id).to(equal("12345"))
                                expect(signRequest.parentFolder.name).to(equal("Contracts"))
                                expect(signRequest.signers[0].redirectUrl).to(equal("https://box.com/redirect_url_signer_1"))
                                expect(signRequest.signers[0].declinedRedirectUrl).to(equal("https://box.com/declined_redirect_url_signer_1"))
                                expect(signRequest.signers[0].inputs?[0].documentTagId).to(equal("1234"))
                                expect(signRequest.signers[0].inputs?[0].textValue).to(equal("text"))
                                expect(signRequest.signers[0].inputs?[0].contentType).to(equal(.text))
                                expect(signRequest.signers[0].inputs?[1].documentTagId).to(equal("4567"))
                                expect(signRequest.signers[0].inputs?[1].dateValue).to(equal("2021-12-03".iso8601))
                                expect(signRequest.signers[0].inputs?[1].contentType).to(equal(.date))
                                expect(signRequest.prefillTags?[0].documentTagId).to(equal("1234"))
                                expect(signRequest.prefillTags?[0].textValue).to(equal("text"))
                                expect(signRequest.prefillTags?[1].documentTagId).to(equal("4567"))
                                expect(signRequest.prefillTags?[1].dateValue).to(equal("2021-12-03".iso8601))
                                expect(signRequest.emailSubject).to(equal("Sign Request from Acme"))
                                expect(signRequest.emailMessage).to(equal("Hello! Please sign the document below"))
                                expect(signRequest.externalId).to(equal("123"))
                                expect(signRequest.daysValid).to(equal(2))
                                expect(signRequest.redirectUrl).to(equal("https://box.com/redirect_url"))
                                expect(signRequest.declinedRedirectUrl).to(equal("https://box.com/declined_redirect_url"))
                            case let .failure(error):
                                fail("Expected call to create to succeed, but it failed: \(error)")
                            }
                            done()
                        }
                    }
                }
            }

            describe("list()") {

                it("should make API call to get all sign requests when call is successful") {
                    stub(
                        condition: isHost("api.box.com")
                            && isPath("/2.0/sign_requests")
                            && isMethodGET()
                    ) { _ in
                        OHHTTPStubsResponse(
                            fileAtPath: OHPathForFile("GetSignRequests.json", type(of: self))!,
                            statusCode: 200, headers: ["Content-Type": "application/json"]
                        )
                    }

                    waitUntil(timeout: .seconds(10)) { done in
                        let iterator = self.sut.signRequests.list()
                        iterator.next { result in
                            switch result {
                            case let .success(page):
                                let firstSignRequest = page.entries[0]
                                expect(firstSignRequest).toNot(beNil())
                                expect(firstSignRequest.id).to(equal("12345"))
                                expect(firstSignRequest.signers.first?.email).to(equal("example@gmail.com"))
                                let firstInput = firstSignRequest.signers[0].inputs?[0]
                                expect(firstInput?.dateValue).to(equal("2021-04-26".iso8601))
                                expect(firstInput?.textValue).to(equal("April 26, 2021"))
                                expect(firstSignRequest.sourceFiles.first?.id).to(equal("12345"))
                                expect(firstSignRequest.sourceFiles.first?.name).to(equal("Contract.pdf"))
                                expect(firstSignRequest.parentFolder.id).to(equal("12345"))
                                expect(firstSignRequest.parentFolder.name).to(equal("Contracts"))
                                expect(firstSignRequest.emailSubject).to(equal("Sign Request from Acme"))
                                expect(firstSignRequest.emailMessage).to(equal("Hello! Please sign the document below"))
                                expect(firstSignRequest.externalId).to(equal("123"))
                                expect(firstSignRequest.daysValid).to(equal(2))
                            case let .failure(error):
                                fail("Unable to get sign requests instead got \(error)")
                            }

                            done()
                        }
                    }
                }
            }

            describe("getById()") {

                it("should make API call to get sign request response when call is successful") {
                    stub(
                        condition: isHost("api.box.com")
                            && isPath("/2.0/sign_requests/12345")
                            && isMethodGET()
                    ) { _ in
                        OHHTTPStubsResponse(
                            fileAtPath: OHPathForFile("GetSignRequest.json", type(of: self))!,
                            statusCode: 200, headers: ["Content-Type": "application/json"]
                        )
                    }

                    waitUntil(timeout: .seconds(10)) { done in
                        self.sut.signRequests.getById(id: "12345") { result in
                            switch result {
                            case let .success(signRequest):
                                expect(signRequest).toNot(beNil())
                                expect(signRequest.id).to(equal("12345"))
                                expect(signRequest.signers.first?.email).to(equal("example@gmail.com"))
                                expect(signRequest.sourceFiles.first?.id).to(equal("12345"))
                                expect(signRequest.sourceFiles.first?.name).to(equal("Contract.pdf"))
                                expect(signRequest.parentFolder.id).to(equal("12345"))
                                expect(signRequest.parentFolder.name).to(equal("Contracts"))
                                expect(signRequest.emailSubject).to(equal("Sign Request from Acme"))
                                expect(signRequest.emailMessage).to(equal("Hello! Please sign the document below"))
                                expect(signRequest.externalId).to(equal("123"))
                                expect(signRequest.daysValid).to(equal(2))
                            case let .failure(error):
                                fail("Unable to get sign request instead got \(error)")
                            }

                            done()
                        }
                    }
                }
            }

            describe("resendById()") {

                it("should make API call to resend a sign request when call is successful") {
                    stub(
                        condition: isHost("api.box.com")
                            && isPath("/2.0/sign_requests/12345/resend")
                            && isMethodPOST()
                    ) { _ in
                        OHHTTPStubsResponse(data: Data(), statusCode: 202, headers: [:])
                    }

                    waitUntil(timeout: .seconds(10)) { done in
                        self.sut.signRequests.resendById(id: "12345") { result in
                            switch result {
                            case .success:
                                break
                            case let .failure(error):
                                fail("Expected call to resend to suceeded, but instead got \(error)")
                            }

                            done()
                        }
                    }
                }
            }

            describe("cancelById()") {

                it("should make API call to cancel a sign request when call is successful") {
                    stub(
                        condition: isHost("api.box.com")
                            && isPath("/2.0/sign_requests/12345/cancel")
                            && isMethodPOST()
                    ) { _ in
                        OHHTTPStubsResponse(
                            fileAtPath: OHPathForFile("CancelSignRequest.json", type(of: self))!,
                            statusCode: 200, headers: ["Content-Type": "application/json"]
                        )
                    }

                    waitUntil(timeout: .seconds(10)) { done in
                        self.sut.signRequests.cancelById(id: "12345") { result in
                            switch result {
                            case let .success(signRequest):
                                expect(signRequest).toNot(beNil())
                                expect(signRequest.id).to(equal("12345"))
                                expect(signRequest.status).to(equal(.cancelled))

                            case let .failure(error):
                                fail("Unable to cancel sign request instead got \(error)")
                            }

                            done()
                        }
                    }
                }
            }
        }
    }
}
