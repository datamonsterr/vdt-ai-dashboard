export enum UserRole {
  USER_ROLE_UNSPECIFIED = 0,
  USER_ROLE_ADMIN = 1,
  USER_ROLE_USER = 2,
  USER_ROLE_VIEWER = 3,
}

export interface User {
  id: string;
  email: string;
  name?: string;
  role?: UserRole;
  createdAt?: Date;
  updatedAt?: Date;
}
