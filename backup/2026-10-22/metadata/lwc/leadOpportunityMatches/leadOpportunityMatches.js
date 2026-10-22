import { LightningElement, api, wire } from 'lwc';
import getOpenOpportunities from '@salesforce/apex/LeadOpportunityMatchController.getOpenOpportunities';

export default class LeadOpportunityMatches extends LightningElement {
    @api recordId;
    opportunities = [];

    @wire(getOpenOpportunities, { leadId: '$recordId' })
    wiredOpportunities({ data, error }) {
        if (data) {
            this.opportunities = data.map((opp) => ({ ...opp, url: `/lightning/r/Opportunity/${opp.id}/view` }));
        } else if (error) {
            this.opportunities = [];
        }
    }

    get hasMatches() {
        return this.opportunities.length > 0;
    }

    get heading() {
        const n = this.opportunities.length;
        return n === 1
            ? 'This company already has 1 open opportunity'
            : `This company already has ${n} open opportunities`;
    }
}