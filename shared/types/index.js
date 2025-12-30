"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotificationType = exports.WorkflowStage = exports.RequestStatus = exports.RequestType = exports.UserRole = void 0;
var UserRole;
(function (UserRole) {
    UserRole["DGS"] = "DGS";
    UserRole["DDGS"] = "DDGS";
    UserRole["ADGS"] = "ADGS";
    UserRole["TO"] = "TO";
    UserRole["DDICT"] = "DDICT";
    UserRole["SO"] = "SO";
    UserRole["SUPERVISOR"] = "SUPERVISOR";
})(UserRole || (exports.UserRole = UserRole = {}));
var RequestType;
(function (RequestType) {
    RequestType["VEHICLE"] = "VEHICLE";
    RequestType["ICT"] = "ICT";
    RequestType["STORE"] = "STORE";
})(RequestType || (exports.RequestType = RequestType = {}));
var RequestStatus;
(function (RequestStatus) {
    RequestStatus["PENDING"] = "PENDING";
    RequestStatus["APPROVED"] = "APPROVED";
    RequestStatus["REJECTED"] = "REJECTED";
    RequestStatus["CORRECTED"] = "CORRECTED";
    RequestStatus["ASSIGNED"] = "ASSIGNED";
    RequestStatus["FULFILLED"] = "FULFILLED";
    RequestStatus["COMPLETED"] = "COMPLETED";
})(RequestStatus || (exports.RequestStatus = RequestStatus = {}));
var WorkflowStage;
(function (WorkflowStage) {
    WorkflowStage["SUBMITTED"] = "SUBMITTED";
    WorkflowStage["SUPERVISOR_REVIEW"] = "SUPERVISOR_REVIEW";
    WorkflowStage["DGS_REVIEW"] = "DGS_REVIEW";
    WorkflowStage["DDGS_REVIEW"] = "DDGS_REVIEW";
    WorkflowStage["ADGS_REVIEW"] = "ADGS_REVIEW";
    WorkflowStage["DDICT_REVIEW"] = "DDICT_REVIEW";
    WorkflowStage["TO_REVIEW"] = "TO_REVIEW";
    WorkflowStage["SO_REVIEW"] = "SO_REVIEW";
    WorkflowStage["FULFILLMENT"] = "FULFILLMENT";
})(WorkflowStage || (exports.WorkflowStage = WorkflowStage = {}));
var NotificationType;
(function (NotificationType) {
    NotificationType["REQUEST_SUBMITTED"] = "REQUEST_SUBMITTED";
    NotificationType["REQUEST_APPROVED"] = "REQUEST_APPROVED";
    NotificationType["REQUEST_REJECTED"] = "REQUEST_REJECTED";
    NotificationType["REQUEST_CORRECTED"] = "REQUEST_CORRECTED";
    NotificationType["REQUEST_ASSIGNED"] = "REQUEST_ASSIGNED";
    NotificationType["REQUEST_FULFILLED"] = "REQUEST_FULFILLED";
    NotificationType["APPROVAL_REQUIRED"] = "APPROVAL_REQUIRED";
})(NotificationType || (exports.NotificationType = NotificationType = {}));
//# sourceMappingURL=index.js.map