import{IsIn,IsOptional,IsString,IsUUID,Length}from'class-validator';
export class CreateQuestionDto{@IsString()@Length(3,160)title:string;@IsString()@Length(3,4000)body:string;@IsIn(['question','productRequest','serviceRequest','localInquiry','recommendation','propertyRequest','jobRequest'])type:string;@IsUUID()cityId:string;@IsOptional()@IsUUID()areaId?:string;@IsOptional()@IsUUID()villageId?:string;}
export class CreateAnswerDto{@IsString()@Length(1,3000)body:string;}
export class CreateReportDto{@IsString()targetType:string;@IsString()targetId:string;@IsString()@Length(3,500)reason:string;}
