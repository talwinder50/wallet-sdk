/*
Copyright Avast Software. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
*/

// Package walleterror defines the error model for the Go API.
package walleterror

import "fmt"

const (
	validationError     = 0
	executionError      = 1
	systemError         = 2
	incorrectUsageError = 3
)

// Error represents an error returned by the Go API.
type Error struct {
	// A short, alphanumeric code that includes the Category.
	Code string
	// A short descriptor of the general category of error. This will always be a pre-defined string.
	Category string
	// A short message describing the error that occurred. Only used in certain cases. It will be blank in all others.
	Message string
	// The full underlying error.
	ParentError string
}

// NewValidationError creates validation error.
func NewValidationError(module string, code int, category string, parentError error) *Error {
	return &Error{
		Code:        getErrorCode(module, validationError, code),
		Category:    category,
		ParentError: parentError.Error(),
	}
}

// NewExecutionError creates execution error.
func NewExecutionError(module string, code int, scenario string, cause error) *Error {
	return &Error{
		Code:        getErrorCode(module, executionError, code),
		Category:    scenario,
		ParentError: cause.Error(),
	}
}

// NewExecutionErrorWithMessage creates an execution error with an additional short error message.
func NewExecutionErrorWithMessage(module string, code int, category, message string, parentError error) *Error {
	return &Error{
		Code:        getErrorCode(module, executionError, code),
		Category:    category,
		Message:     message,
		ParentError: parentError.Error(),
	}
}

// NewSystemError creates system error.
func NewSystemError(module string, code int, category string, parentError error) *Error {
	return &Error{
		Code:        getErrorCode(module, systemError, code),
		Category:    category,
		ParentError: parentError.Error(),
	}
}

// NewInvalidSDKUsageError creates a new invalid SDK usage error, used to indicate when a Wallet-SDK API is used
// incorrectly.
func NewInvalidSDKUsageError(module string, parentError error) *Error {
	return &Error{
		Code:        getErrorCode(module, incorrectUsageError, 0),
		Category:    "INVALID_SDK_USAGE",
		ParentError: parentError.Error(),
	}
}

// Error returns string representation of error.
func (e *Error) Error() string {
	return fmt.Sprintf("%s(%s):%s", e.Category, e.Code, e.ParentError)
}

func getErrorCode(module string, errType, code int) string {
	return fmt.Sprintf("%s%d-%04d", module, errType, code)
}
