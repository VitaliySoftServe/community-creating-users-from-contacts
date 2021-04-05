import { LightningElement } from 'lwc';
import createNewUsersFromContactsByStates from '@salesforce/apex/ContactsToUsersController.createNewUsersFromContactsByStates';
import checkContacts from '@salesforce/apex/ContactsToUsersController.checkContacts';
import { NavigationMixin } from 'lightning/navigation';

export default class CreatingUsersFromContacts extends NavigationMixin(
    LightningElement
) {
    isLoading = false;
    logsExist = false;
    logs;
    selected = [];
    isClearLogsDisabled = true;
    isDownloadReportDisabled = true;
    
    get showSelected() {
        let fullNames = [];
        this.selected.forEach((element) => {
            fullNames.push(
                ' ' + this.states.find((e) => e.value === element).label
            );
        });
        return fullNames;
    }

    get isCreateUsersDisabled() {
        return !this.selected.length;
    }

    get isCheckContactsDisabled() {
        return !this.selected.length;
    }

    get states() {
        return [
            { label: 'Alabama (AL)', value: 'AL' },
            { label: 'Alaska (AK)', value: 'AK' },
            { label: 'Arizona (AZ)', value: 'AZ' },
            { label: 'Arkansas (AR)', value: 'AR' },
            { label: 'California (CA)', value: 'CA' },
            { label: 'Colorado (CO)', value: 'CO' },
            { label: 'Connecticut (CT)', value: 'CT' },
            { label: 'Delaware (DE)', value: 'DE' },
            { label: 'District of Columbia (DC)', value: 'DC' },
            { label: 'Florida (GA)', value: 'GA' },
            { label: 'Georgia (FL)', value: 'FL' },
            { label: 'Idaho (ID)', value: 'ID' },
            { label: 'Illinois (IL)', value: 'IL' },
            { label: 'Indiana (IN)', value: 'IN' },
            { label: 'Iowa (IA)', value: 'IA' },
            { label: 'Kansas (KS)', value: 'KS' },
            { label: 'Kentucky (KY)', value: 'KY' },
            { label: 'Louisiana (LA)', value: 'LA' },
            { label: 'Maine (ME)', value: 'ME' },
            { label: 'Maryland (MD)', value: 'MD' },
            { label: 'Massachusetts (MA)', value: 'MA' },
            { label: 'Michigan (MI)', value: 'MI' },
            { label: 'Minnesota (MN)', value: 'MN' },
            { label: 'Mississippi (MS)', value: 'MS' },
            { label: 'Missouri (MO)', value: 'MO' },
            { label: 'Montana (MT)', value: 'MT' },
            { label: 'Nebraska (NE)', value: 'NE' },
            { label: 'Nevada (NV)', value: 'NV' },
            { label: 'New Hampshire (NH)', value: 'NH' },
            { label: 'New Jersey (NJ)', value: 'NJ' },
            { label: 'New York (NY)', value: 'NY' },
            { label: 'North Carolina (NC)', value: 'NC' },
            { label: 'North Dakota (ND)', value: 'ND' },
            { label: 'Ohio (OH)', value: 'OH' },
            { label: 'Oklahoma (OK)', value: 'OK' },
            { label: 'Oregon (OR)', value: 'OR' },
            { label: 'Pennsylvania (PA)', value: 'PA' },
            { label: 'Rhode Island (RI)', value: 'RI' },
            { label: 'South Carolina (SC)', value: 'SC' },
            { label: 'South Dakota (SD)', value: 'SD' },
            { label: 'Tennessee (TN)', value: 'TN' },
            { label: 'Texas (TX)', value: 'TX' },
            { label: 'Utah (UT)', value: 'UT' },
            { label: 'Vermont (VT)', value: 'VT' },
            { label: 'Virginia (VA)', value: 'VA' },
            { label: 'Washington (WA)', value: 'WA' },
            { label: 'West Virginia (WV)', value: 'WV' },
            { label: 'Wisconsin (WI)', value: 'WI' },
            { label: 'Wyoming (WY)', value: 'WY' }
        ];
    }

    handleChange(event) {
        this.selected = event.detail.value;
    }

    handleCreateUsers() {
        this.isLoading = true;
        createNewUsersFromContactsByStates({ states: this.selected })
            .then((result) => {
                this.logs = result;
                this.logsExist = true;
                this.isLoading = false;
                this.isClearLogsDisabled = false;
                this.isDownloadReportDisabled = false;
            })
            .catch((error) => {
                this.logs = '<span style="color:red">' + error + '</span>';
                this.logsExist = true;
                this.isLoading = false;
                this.isClearLogsDisabled = false;
                this.isDownloadReportDisabled = false;
            });
    }

    handleClearLogs() {
        this.logs = '';
        this.logsExist = false;
        this.isClearLogsDisabled = true;
        this.isDownloadReportDisabled = true;
    }

    handleCheckContacts() {
        this.isLoading = true;
        checkContacts({ states: this.selected })
            .then((result) => {
                this.logs = result;
                this.logsExist = true;
                this.isLoading = false;
                this.isClearLogsDisabled = false;
                this.isDownloadReportDisabled = false;
            })
            .catch((error) => {
                this.logs = '<span style="color:red">' + error + '</span>';
                this.logsExist = true;
                this.isLoading = false;
                this.isClearLogsDisabled = false;
                this.isDownloadReportDisabled = false;
            });
    }

    handleDownloadReport() {
        var element = document.createElement('a');
        element.setAttribute(
            'href',
            'data:text/plain;charset=utf-8,' +
                encodeURIComponent(this.convertToPlainText(this.logs))
        );
        element.setAttribute(
            'download',
            'Creating Users Report - ' + new Date().toDateString()
        );

        element.style.display = 'none';
        document.body.appendChild(element);

        element.click();

        document.body.removeChild(element);
    }

    convertToPlainText(text) {
        const regex1 = /(?:<br>|<\/h4>)/gi;
        const regex2 = /(?:<b>|<\/b>|<h4>|<\/h4>|<\/span>|<span style="color:rgba(0,68,135,255)">|<span style="color:red">)/gi;
        text = text.replaceAll(regex1, '\n');
        text = text.replaceAll(regex2, '');
        return text;
    }

    showPdf() {
        let logs = this.logs.replaceAll('#004487', 'navy');
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'customTabName'
            },
            state: {
                c__showPanel: 'true',
                name: 'name'
            }
        }).then(() => {
            window.open('/apex/DownloadContactsToUsersPdfHelper?text=' + logs);
        });
    }
}
