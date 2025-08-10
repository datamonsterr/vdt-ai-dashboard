import {  } from '@prisma/client';
import { faker } from '@faker-js/faker';
import Decimal from 'decimal.js';



export function fakeOrganization() {
  return {
    name: faker.person.fullName(),
    slug: faker.lorem.words(5),
  };
}
export function fakeOrganizationComplete() {
  return {
    id: faker.string.uuid(),
    name: faker.person.fullName(),
    slug: faker.lorem.words(5),
    createdAt: new Date(),
    updatedAt: new Date(),
  };
}
export function fakeProject() {
  return {
    name: faker.person.fullName(),
    slug: faker.lorem.words(5),
    description: undefined,
    createdBy: undefined,
  };
}
export function fakeProjectComplete() {
  return {
    id: faker.string.uuid(),
    organizationId: faker.string.uuid(),
    name: faker.person.fullName(),
    slug: faker.lorem.words(5),
    description: undefined,
    createdBy: undefined,
    createdAt: new Date(),
    updatedAt: new Date(),
  };
}
export function fakeUser() {
  return {
    clerkUserId: faker.lorem.words(5),
    email: faker.internet.email(),
    displayName: undefined,
  };
}
export function fakeUserComplete() {
  return {
    id: faker.string.uuid(),
    clerkUserId: faker.lorem.words(5),
    email: faker.internet.email(),
    displayName: undefined,
    createdAt: new Date(),
    updatedAt: new Date(),
  };
}
