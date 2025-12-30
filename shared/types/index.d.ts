export declare enum UserRole {
    DGS = "DGS",
    DDGS = "DDGS",
    ADGS = "ADGS",
    TO = "TO",
    DDICT = "DDICT",
    SO = "SO",
    SUPERVISOR = "SUPERVISOR"
}
export declare enum RequestType {
    VEHICLE = "VEHICLE",
    ICT = "ICT",
    STORE = "STORE"
}
export declare enum RequestStatus {
    PENDING = "PENDING",
    APPROVED = "APPROVED",
    REJECTED = "REJECTED",
    CORRECTED = "CORRECTED",
    ASSIGNED = "ASSIGNED",
    FULFILLED = "FULFILLED",
    COMPLETED = "COMPLETED"
}
export declare enum WorkflowStage {
    SUBMITTED = "SUBMITTED",
    SUPERVISOR_REVIEW = "SUPERVISOR_REVIEW",
    DGS_REVIEW = "DGS_REVIEW",
    DDGS_REVIEW = "DDGS_REVIEW",
    ADGS_REVIEW = "ADGS_REVIEW",
    DDICT_REVIEW = "DDICT_REVIEW",
    TO_REVIEW = "TO_REVIEW",
    SO_REVIEW = "SO_REVIEW",
    FULFILLMENT = "FULFILLMENT"
}
export declare enum NotificationType {
    REQUEST_SUBMITTED = "REQUEST_SUBMITTED",
    REQUEST_APPROVED = "REQUEST_APPROVED",
    REQUEST_REJECTED = "REQUEST_REJECTED",
    REQUEST_CORRECTED = "REQUEST_CORRECTED",
    REQUEST_ASSIGNED = "REQUEST_ASSIGNED",
    REQUEST_FULFILLED = "REQUEST_FULFILLED",
    APPROVAL_REQUIRED = "APPROVAL_REQUIRED"
}
export interface Approval {
    approverId: string;
    role: UserRole;
    status: 'APPROVED' | 'REJECTED';
    comment?: string;
    timestamp: Date;
}
export interface Correction {
    requestedBy: string;
    role: UserRole;
    comment: string;
    timestamp: Date;
    resolved: boolean;
}
